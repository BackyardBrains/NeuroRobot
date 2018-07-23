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
"""Command for updating managed instance group."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import managed_instance_groups_utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute import scope as compute_scope
from googlecloudsdk.command_lib.compute.instance_groups import flags as instance_groups_flags


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class Update(base.UpdateCommand):
  r"""Update Google Compute Engine managed instance groups.

  *{command}* allows to update StatefulPolicy for a managed instance group.
  Stateful Policy defines what stateful resources should be preserved for the
  group. When instances in the group are removed or recreated, those stateful
  properties are always applied to them. This command allows to change the
  preserved resources by adding more disks or removing existing disks and to
  turn on and off preserving instance names.

  Example:

    $ {command} example-group --add-stateful-disks my-disk-1,my-disk-2 \
    --remove-stateful-disks my-disk-0

  will for each instance mark disk `my-disk-0` as not stateful and disks
  `my-disk-1` and `my-disk-2` as stateful. That means that disks `my-disk-1`
  and `my-disk-2` will be preserved when the instances get recreated or
  restarted, while disk `my-disk-0` will not be preserved anymore.

  When there are any disks marked as stateful, the instances automatically
  will be assigned stateful names as well. You cannot turn off stateful names
  without marking all disks as non-stateful.
  """

  @staticmethod
  def Args(parser):
    instance_groups_flags.MULTISCOPE_INSTANCE_GROUP_MANAGER_ARG.AddArgument(
        parser, operation_type='update')
    instance_groups_flags.AddMigUpdateStatefulFlags(parser)

  def _UpdateStatefulPolicy(self, client, device_names):
    preserved_disks = [
        client.messages.StatefulPolicyPreservedDisk(deviceName=device_name)
        for device_name in device_names
    ]
    if preserved_disks:
      return client.messages.StatefulPolicy(
          preservedResources=client.messages.StatefulPolicyPreservedResources(
              disks=preserved_disks))
    else:
      return client.messages.StatefulPolicy()

  def _MakeUpdateRequest(self, client, igm_ref, igm_updated_resource):
    if igm_ref.Collection() == 'compute.instanceGroupManagers':
      service = client.apitools_client.instanceGroupManagers
      request = client.messages.ComputeInstanceGroupManagersUpdateRequest(
          instanceGroupManager=igm_ref.Name(),
          instanceGroupManagerResource=igm_updated_resource,
          project=igm_ref.project,
          zone=igm_ref.zone)
    elif igm_ref.Collection() == 'compute.regionInstanceGroupManagers':
      service = client.apitools_client.regionInstanceGroupManagers
      request = client.messages.ComputeRegionInstanceGroupManagersUpdateRequest(
          instanceGroupManager=igm_ref.Name(),
          instanceGroupManagerResource=igm_updated_resource,
          project=igm_ref.project,
          region=igm_ref.region)
    else:
      raise ValueError('Unknown reference type {0}'.format(
          igm_ref.Collection()))
    return client.MakeRequests([(service, 'Update', request)])

  def _MakePatchRequest(self, client, igm_ref, igm_updated_resource):
    if igm_ref.Collection() == 'compute.instanceGroupManagers':
      service = client.apitools_client.instanceGroupManagers
      request = client.messages.ComputeInstanceGroupManagersPatchRequest(
          instanceGroupManager=igm_ref.Name(),
          instanceGroupManagerResource=igm_updated_resource,
          project=igm_ref.project,
          zone=igm_ref.zone)
    elif igm_ref.Collection() == 'compute.regionInstanceGroupManagers':
      service = client.apitools_client.regionInstanceGroupManagers
      request = client.messages.ComputeRegionInstanceGroupManagersPatchRequest(
          instanceGroupManager=igm_ref.Name(),
          instanceGroupManagerResource=igm_updated_resource,
          project=igm_ref.project,
          region=igm_ref.region)
    else:
      raise ValueError('Unknown reference type {0}'.format(
          igm_ref.Collection()))
    return client.MakeRequests([(service, 'Patch', request)])

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    igm_ref = (instance_groups_flags.MULTISCOPE_INSTANCE_GROUP_MANAGER_ARG.
               ResolveAsResource)(
                   args,
                   holder.resources,
                   default_scope=compute_scope.ScopeEnum.ZONE,
                   scope_lister=flags.GetDefaultScopeLister(client))

    igm_resource = managed_instance_groups_utils.GetInstanceGroupManagerOrThrow(
        igm_ref, client)

    device_names = instance_groups_flags.GetValidatedUpdateStatefulPolicyParams(
        args, igm_resource.statefulPolicy)

    if not device_names:
      # TODO(b/70314588): Use Patch instead of manual Update.
      if args.IsSpecified(
          'stateful_names') and not args.GetValue('stateful_names'):
        igm_resource.reset('statefulPolicy')
      elif igm_resource.statefulPolicy or args.GetValue('stateful_names'):
        igm_resource.statefulPolicy = self._UpdateStatefulPolicy(client, [])
      return self._MakeUpdateRequest(client, igm_ref, igm_resource)

    stateful_policy = self._UpdateStatefulPolicy(client, device_names)
    igm_updated_resource = client.messages.InstanceGroupManager(
        statefulPolicy=stateful_policy)

    return self._MakePatchRequest(client, igm_ref, igm_updated_resource)
