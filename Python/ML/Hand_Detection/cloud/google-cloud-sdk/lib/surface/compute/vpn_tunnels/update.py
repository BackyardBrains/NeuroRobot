# Copyright 2017 Google Inc. All Rights Reserved.
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
"""Command to update labels for VPN tunnels."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute.operations import poller
from googlecloudsdk.api_lib.util import waiter
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions as calliope_exceptions
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.vpn_tunnels import flags as vpn_tunnel_flags
from googlecloudsdk.command_lib.util.args import labels_util


@base.ReleaseTracks(base.ReleaseTrack.ALPHA, base.ReleaseTrack.BETA)
class Update(base.UpdateCommand):
  r"""Update a Google Compute Engine VPN tunnel.

  *{command}* updates labels for a Google Compute Engine
  VPN tunnel.  For example:

    $ {command} example-tunnel --region us-central1 \
      --update-labels=k0=value1,k1=value2 --remove-labels=k3

  will add/update labels ``k0'' and ``k1'' and remove labels with key ``k3''.

  Labels can be used to identify the VPN tunnel and to filter them as in

    $ {parent_command} list --filter='labels.k1:value2'

  To list existing labels

    $ {parent_command} describe example-tunnel --format='default(labels)'

  """

  VPN_TUNNEL_ARG = None

  @classmethod
  def Args(cls, parser):
    """Adds arguments to the supplied parser.

    Args:
      parser: The argparse parser to add arguments to.
    """
    cls.VPN_TUNNEL_ARG = (vpn_tunnel_flags.VpnTunnelArgument())
    cls.VPN_TUNNEL_ARG.AddArgument(parser)
    labels_util.AddUpdateLabelsFlags(parser)

  def _CreateRegionalSetLabelsRequest(self, messages, vpn_tunnel_ref,
                                      vpn_tunnel, replacement):
    """Creates the API request to update labels on a VPN Tunnel.

    Args:
      messages: Module with request messages.
      vpn_tunnel_ref: Resource reference for the VPN tunnel.
      vpn_tunnel: The vpn_tunnel being updated.
      replacement: A new labels request proto representing the update and remove
                   edits.
    Returns:
      Request to be sent to update the VPN tunnel's labels.
    """
    return messages.ComputeVpnTunnelsSetLabelsRequest(
        project=vpn_tunnel_ref.project,
        resource=vpn_tunnel_ref.Name(),
        region=vpn_tunnel_ref.region,
        regionSetLabelsRequest=messages.RegionSetLabelsRequest(
            labelFingerprint=vpn_tunnel.labelFingerprint, labels=replacement))

  def Run(self, args):
    """Issues API requests to update a VPN Tunnel.

    Args:
      args: argparse.Namespace, The arguments received by this command.
    Returns:
      [protorpc.messages.Message], A list of responses returned
      by the compute API.
    """
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client.apitools_client
    messages = holder.client.messages

    vpn_tunnel_ref = self.VPN_TUNNEL_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(holder.client))

    labels_diff = labels_util.Diff.FromUpdateArgs(args)
    if not labels_diff.MayHaveUpdates():
      raise calliope_exceptions.RequiredArgumentException(
          'LABELS', 'At least one of --update-labels or '
          '--remove-labels must be specified.')

    vpn_tunnel = client.vpnTunnels.Get(
        messages.ComputeVpnTunnelsGetRequest(**vpn_tunnel_ref.AsDict()))
    labels_value = messages.RegionSetLabelsRequest.LabelsValue

    labels_update = labels_diff.Apply(labels_value, vpn_tunnel.labels)

    if not labels_update.needs_update:
      return vpn_tunnel

    request = self._CreateRegionalSetLabelsRequest(
        messages, vpn_tunnel_ref, vpn_tunnel, labels_update.labels)

    operation = client.vpnTunnels.SetLabels(request)
    operation_ref = holder.resources.Parse(
        operation.selfLink, collection='compute.regionOperations')

    operation_poller = poller.Poller(client.vpnTunnels)

    return waiter.WaitFor(operation_poller, operation_ref,
                          'Updating labels of VPN tunnel [{0}]'.format(
                              vpn_tunnel_ref.Name()))
