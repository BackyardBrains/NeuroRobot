# Copyright 2018 Google Inc. All Rights Reserved.
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
"""Command for removing resource policies from a disk."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.disks import flags as disks_flags
from googlecloudsdk.command_lib.compute.resource_policies import flags
from googlecloudsdk.command_lib.compute.resource_policies import util


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class DisksRemoveResourcePolicies(base.UpdateCommand):
  """Remove resource policies from a Google Compute Engine disk.

    *{command}* removes resource policies from a Google Compute
    Engine virtual disk.
  """

  @staticmethod
  def Args(parser):
    disks_flags.MakeDiskArg(plural=False).AddArgument(
        parser, operation_type='remove resource policies from')
    flags.AddResourcePoliciesArgs(
        parser, 'removed from', required=True)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    messages = client.messages

    disk_ref = disks_flags.MakeDiskArg(plural=False).ResolveAsResource(
        args, holder.resources)

    resource_policies = []
    for policy in args.resource_policies:
      resource_policy_ref = util.ParseResourcePolicyWithZone(
          holder.resources,
          policy,
          project=disk_ref.project,
          zone=disk_ref.zone)
      resource_policies.append(resource_policy_ref.SelfLink())

    remove_request = messages.ComputeDisksRemoveResourcePoliciesRequest(
        disk=disk_ref.Name(),
        project=disk_ref.project,
        zone=disk_ref.zone,
        disksRemoveResourcePoliciesRequest=
        messages.DisksRemoveResourcePoliciesRequest(
            resourcePolicies=resource_policies))

    return client.MakeRequests([(client.apitools_client.disks,
                                 'RemoveResourcePolicies', remove_request)])
