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
"""Command for setting target pools of managed instance group."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import utils
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute import scope as compute_scope
from googlecloudsdk.command_lib.compute.instance_groups import flags as instance_groups_flags


def _AddArgs(parser):
  """Add args."""
  parser.add_argument(
      '--target-pools',
      required=True,
      type=arg_parsers.ArgList(min_length=0),
      metavar='TARGET_POOL',
      help=('Compute Engine Target Pools to add the instances to. '
            'Target Pools must be specified by name or by URL. Example: '
            '--target-pool target-pool-1,target-pool-2.'))


class SetTargetPools(base.Command):
  """Set target pools of managed instance group.

    *{command}* sets the target pools for an existing managed instance group.
  Instances that are part of the managed instance group will be added to the
  target pool automatically.

  Setting a new target pool won't apply to existing instances in the group
  unless they are recreated using the recreate-instances command. But any new
  instances created in the managed instance group will be added to all of the
  provided target pools for load balancing purposes.
  """

  @staticmethod
  def Args(parser):
    _AddArgs(parser=parser)
    instance_groups_flags.MULTISCOPE_INSTANCE_GROUP_MANAGER_ARG.AddArgument(
        parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    resource_arg = instance_groups_flags.MULTISCOPE_INSTANCE_GROUP_MANAGER_ARG
    default_scope = compute_scope.ScopeEnum.ZONE
    scope_lister = flags.GetDefaultScopeLister(client)
    group_ref = resource_arg.ResolveAsResource(
        args, holder.resources, default_scope=default_scope,
        scope_lister=scope_lister)

    if group_ref.Collection() == 'compute.instanceGroupManagers':
      region = utils.ZoneNameToRegionName(group_ref.zone)
    else:
      region = group_ref.region

    pool_refs = []
    for target_pool in args.target_pools:
      pool_refs.append(holder.resources.Parse(
          target_pool,
          params={
              'project': group_ref.project,
              'region': region
          },
          collection='compute.targetPools'))
    pools = [pool_ref.SelfLink() for pool_ref in pool_refs]

    if group_ref.Collection() == 'compute.instanceGroupManagers':
      service = client.apitools_client.instanceGroupManagers
      request = (
          client.messages.ComputeInstanceGroupManagersSetTargetPoolsRequest(
              instanceGroupManager=group_ref.Name(),
              instanceGroupManagersSetTargetPoolsRequest=(
                  client.messages.InstanceGroupManagersSetTargetPoolsRequest(
                      targetPools=pools)),
              project=group_ref.project,
              zone=group_ref.zone))
    else:
      service = client.apitools_client.regionInstanceGroupManagers
      request = (client.messages.
                 ComputeRegionInstanceGroupManagersSetTargetPoolsRequest(
                     instanceGroupManager=group_ref.Name(),
                     regionInstanceGroupManagersSetTargetPoolsRequest=(
                         client.messages.
                         RegionInstanceGroupManagersSetTargetPoolsRequest(
                             targetPools=pools)),
                     project=group_ref.project,
                     region=group_ref.region))
    return client.MakeRequests([(service, 'SetTargetPools', request)])
