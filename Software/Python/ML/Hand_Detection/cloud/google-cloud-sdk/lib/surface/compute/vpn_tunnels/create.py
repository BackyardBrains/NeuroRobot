# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Command for creating VPN tunnels."""

from __future__ import absolute_import
from __future__ import unicode_literals
import argparse
import re

from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.routers import flags as router_flags
from googlecloudsdk.command_lib.compute.target_vpn_gateways import (
    flags as target_vpn_gateway_flags)
from googlecloudsdk.command_lib.compute.vpn_tunnels import flags


_PRINTABLE_CHARS_PATTERN = r'[ -~]+'


class DeprecatedArgumentException(exceptions.ToolException):

  def __init__(self, arg, msg):
    super(DeprecatedArgumentException, self).__init__(
        '{0} is deprecated. {1}'.format(arg, msg))


def ValidateSimpleSharedSecret(possible_secret):
  """ValidateSimpleSharedSecret checks its argument is a vpn shared secret.

  ValidateSimpleSharedSecret(v) returns v iff v matches [ -~]+.

  Args:
    possible_secret: str, The data to validate as a shared secret.

  Returns:
    The argument, if valid.

  Raises:
    ArgumentTypeError: The argument is not a valid vpn shared secret.
  """

  if not possible_secret:
    raise argparse.ArgumentTypeError(
        '--shared-secret requires a non-empty argument.')

  if re.match(_PRINTABLE_CHARS_PATTERN, possible_secret):
    return possible_secret

  raise argparse.ArgumentTypeError(
      'The argument to --shared-secret is not valid it contains '
      'non-printable charcters.')


class CreateGA(base.CreateCommand):
  """Create a VPN tunnel.

    *{command}* is used to create a VPN tunnel between a VPN Gateway
  in Google Cloud Platform and an external gateway that is
  identified by --peer-address.
  """

  ROUTER_ARG = None
  TARGET_VPN_GATEWAY_ARG = None
  VPN_TUNNEL_ARG = None

  @classmethod
  def Args(cls, parser):
    """Adds arguments to the supplied parser."""
    parser.display_info.AddFormat(flags.DEFAULT_LIST_FORMAT)
    cls.ROUTER_ARG = router_flags.RouterArgumentForVpnTunnel(required=False)
    cls.TARGET_VPN_GATEWAY_ARG = (
        target_vpn_gateway_flags.TargetVpnGatewayArgumentForVpnTunnel())
    cls.TARGET_VPN_GATEWAY_ARG.AddArgument(parser)
    cls.VPN_TUNNEL_ARG = flags.VpnTunnelArgument()
    cls.VPN_TUNNEL_ARG.AddArgument(parser, operation_type='create')

    parser.add_argument(
        '--description',
        help='An optional, textual description for the target VPN tunnel.')

    parser.add_argument(
        '--ike-version',
        choices=[1, 2],
        type=int,
        help='Internet Key Exchange protocol version number. Default is 2.')

    parser.add_argument(
        '--peer-address',
        required=True,
        help='A valid IP-v4 address representing the remote tunnel endpoint')

    parser.add_argument(
        '--shared-secret',
        type=ValidateSimpleSharedSecret,
        required=True,
        help="""\
        A shared secret consisting of printable characters.  Valid
        arguments match the regular expression """ + _PRINTABLE_CHARS_PATTERN)

    parser.add_argument(
        '--ike-networks',
        type=arg_parsers.ArgList(min_length=1),
        hidden=True,
        help='THIS ARGUMENT NEEDS HELP TEXT.')

    parser.add_argument(
        '--local-traffic-selector',
        type=arg_parsers.ArgList(min_length=1),
        metavar='CIDR',
        help=('Traffic selector is an agreement between IKE peers to permit '
              'traffic through a tunnel if the traffic matches a specified pair'
              ' of local and remote addresses.\n\n'
              'local_traffic_selector allows to configure the local addresses '
              'that are permitted. The value should be a comma separated list '
              'of CIDR formatted strings. '
              'Example: 192.168.0.0/16,10.0.0.0/24.'))

    parser.add_argument(
        '--remote-traffic-selector',
        type=arg_parsers.ArgList(min_length=1),
        metavar='CIDR',
        help=('Traffic selector is an agreement between IKE peers to permit '
              'traffic through a tunnel if the traffic matches a specified pair'
              ' of local and remote addresses.\n\n'
              'remote_traffic_selector allows to configure the remote addresses'
              ' that are permitted. The value should be a comma separated list '
              'of CIDR formatted strings. '
              'Example: 192.168.0.0/16,10.0.0.0/24.'))

    # TODO(b/29072646): autocomplete --router argument
    parser.add_argument(
        '--router',
        help='The Router to use for dynamic routing.')

    parser.display_info.AddCacheUpdater(flags.VpnTunnelsCompleter)

  def Run(self, args):
    """Issues API requests to construct VPN Tunnels."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    # TODO(b/38253176) Add test coverage
    if args.ike_networks is not None:
      raise DeprecatedArgumentException(
          '--ike-networks',
          'It has been renamed to --local-traffic-selector.')

    vpn_tunnel_ref = self.VPN_TUNNEL_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(client))

    args.target_vpn_gateway_region = vpn_tunnel_ref.region
    target_vpn_gateway_ref = self.TARGET_VPN_GATEWAY_ARG.ResolveAsResource(
        args, holder.resources)

    # TODO(b/38253800) Add test coverage
    router_link = None
    if args.router is not None:
      args.router_region = vpn_tunnel_ref.region
      router_ref = self.ROUTER_ARG.ResolveAsResource(args, holder.resources)
      router_link = router_ref.SelfLink()

    request = client.messages.ComputeVpnTunnelsInsertRequest(
        project=vpn_tunnel_ref.project,
        region=vpn_tunnel_ref.region,
        vpnTunnel=client.messages.VpnTunnel(
            description=args.description,
            router=router_link,
            localTrafficSelector=args.local_traffic_selector or [],
            remoteTrafficSelector=args.remote_traffic_selector or [],
            ikeVersion=args.ike_version,
            name=vpn_tunnel_ref.Name(),
            peerIp=args.peer_address,
            sharedSecret=args.shared_secret,
            targetVpnGateway=target_vpn_gateway_ref.SelfLink()))

    return client.MakeRequests([(client.apitools_client.vpnTunnels, 'Insert',
                                 request)])
