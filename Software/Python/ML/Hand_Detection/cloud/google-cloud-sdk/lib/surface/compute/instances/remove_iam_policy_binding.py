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
"""Command to remove an IAM policy binding from an instance resource."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.instances import flags
from googlecloudsdk.command_lib.iam import iam_util


@base.Hidden
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class RemoveIamPolicyBinding(base.Command):
  """Remove an IAM policy binding from a Google Compute Engine instance.

  *{command}* removes an IAM policy binding from a Google Compute Engine
  instance's access policy.
  """
  detailed_help = iam_util.GetDetailedHelpForRemoveIamPolicyBinding(
      'instance', 'my-instance', role='roles/compute.securityAdmin',
      use_an=True)

  @staticmethod
  def Args(parser):
    flags.INSTANCE_ARG.AddArgument(
        parser, operation_type='remove the IAM policy binding from')
    iam_util.AddArgsForRemoveIamPolicyBinding(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    instance_ref = flags.INSTANCE_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=flags.GetInstanceZoneScopeLister(client))

    policy = client.MakeRequests(
        [(client.apitools_client.instances, 'GetIamPolicy',
          client.messages.ComputeInstancesGetIamPolicyRequest(
              resource=instance_ref.instance,
              zone=instance_ref.zone,
              project=instance_ref.project))])[0]
    iam_util.RemoveBindingFromIamPolicy(policy, args.member, args.role)
    # TODO(b/78371568): Construct the ZoneSetPolicyRequest directly
    # out of the parsed policy.
    return client.MakeRequests(
        [(client.apitools_client.instances, 'SetIamPolicy',
          client.messages.ComputeInstancesSetIamPolicyRequest(
              zoneSetPolicyRequest=client.messages.ZoneSetPolicyRequest(
                  bindings=policy.bindings,
                  etag=policy.etag),
              project=instance_ref.project,
              resource=instance_ref.instance,
              zone=instance_ref.zone))])[0]
