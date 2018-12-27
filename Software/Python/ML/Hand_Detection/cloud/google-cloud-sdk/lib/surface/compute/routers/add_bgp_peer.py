# Copyright 2015 Google Inc. All Rights Reserved.
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
"""Command for adding a BGP peer to a Google Compute Engine router."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute.operations import poller
from googlecloudsdk.api_lib.util import waiter
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.routers import flags
from googlecloudsdk.command_lib.compute.routers import router_utils
from googlecloudsdk.core import log
from googlecloudsdk.core import resources
import six


class AddBgpPeer(base.UpdateCommand):
  """Add a BGP peer to a Google Compute Engine router."""

  ROUTER_ARG = None

  @classmethod
  def Args(cls, parser):
    cls.ROUTER_ARG = flags.RouterArgument()
    cls.ROUTER_ARG.AddArgument(parser)
    base.ASYNC_FLAG.AddToParser(parser)
    flags.AddBgpPeerArgs(parser, for_add_bgp_peer=True)
    flags.AddReplaceCustomAdvertisementArgs(parser, 'peer')

  def Run(self, args):
    """See base.UpdateCommand."""

    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    messages = holder.client.messages
    service = holder.client.apitools_client.routers

    router_ref = self.ROUTER_ARG.ResolveAsResource(args, holder.resources)

    request_type = messages.ComputeRoutersGetRequest
    replacement = service.Get(request_type(**router_ref.AsDict()))

    peer = _CreateBgpPeerMessage(messages, args)

    if router_utils.HasReplaceAdvertisementFlags(args):
      mode, groups, ranges = router_utils.ParseAdvertisements(
          messages=messages, resource_class=messages.RouterBgpPeer, args=args)

      attrs = {
          'advertiseMode': mode,
          'advertisedGroups': groups,
          'advertisedIpRanges': ranges,
      }

      for attr, value in six.iteritems(attrs):
        if value is not None:
          setattr(peer, attr, value)

    replacement.bgpPeers.append(peer)

    result = service.Patch(
        messages.ComputeRoutersPatchRequest(
            project=router_ref.project,
            region=router_ref.region,
            router=router_ref.Name(),
            routerResource=replacement))

    operation_ref = resources.REGISTRY.Parse(
        result.name,
        collection='compute.regionOperations',
        params={
            'project': router_ref.project,
            'region': router_ref.region,
        })

    if args.async:
      log.UpdatedResource(
          operation_ref,
          kind='router [{0}] to add peer [{1}]'.format(router_ref.Name(),
                                                       peer.name),
          is_async=True,
          details='Run the [gcloud compute operations describe] command '
          'to check the status of this operation.')
      return result

    target_router_ref = holder.resources.Parse(
        router_ref.Name(),
        collection='compute.routers',
        params={
            'project': router_ref.project,
            'region': router_ref.region,
        })

    operation_poller = poller.Poller(service, target_router_ref)
    return waiter.WaitFor(operation_poller, operation_ref,
                          'Creating peer [{0}] in router [{1}]'.format(
                              peer.name, router_ref.Name()))


def _CreateBgpPeerMessage(messages, args):
  """Creates a BGP peer with base attributes based on flag arguments."""

  return messages.RouterBgpPeer(
      name=args.peer_name,
      interfaceName=args.interface,
      peerIpAddress=args.peer_ip_address,
      peerAsn=args.peer_asn,
      advertisedRoutePriority=args.advertised_route_priority)
