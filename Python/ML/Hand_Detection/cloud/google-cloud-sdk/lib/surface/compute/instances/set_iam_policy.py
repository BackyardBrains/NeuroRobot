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
"""Command to set IAM policy for an instance resource."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.instances import flags
from googlecloudsdk.command_lib.iam import iam_util


@base.Hidden
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class SetIamPolicy(base.Command):
  """Set the IAM Policy for a Google Compute Engine instance.

  *{command}* sets the IAM Policy associated with a Google Compute Engine
  instance in a project.
  """

  detailed_help = iam_util.GetDetailedHelpForSetIamPolicy(
      'instance', 'my-instance', use_an=True)

  @staticmethod
  def Args(parser):
    flags.INSTANCE_ARG.AddArgument(
        parser, operation_type='set the IAM policy of')
    compute_flags.AddPolicyFileFlag(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    policy = iam_util.ParsePolicyFile(args.policy_file, client.messages.Policy)

    instance_ref = flags.INSTANCE_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(client))

    # TODO(b/78371568): Construct the ZoneSetPolicyRequest directly
    # out of the parsed policy instead of setting 'bindings' and 'etags'.
    # This current form is required so gcloud won't break while Compute
    # roll outs the breaking change to SetIamPolicy (b/75971480)

    # TODO(b/36053578): determine how this output should look when empty.

    # SetIamPolicy always returns either an error or the newly set policy.
    # If the policy was just set to the empty policy it returns a valid empty
    # policy (just an etag.)
    # It is not possible to have multiple policies for one resource.
    return client.MakeRequests(
        [(client.apitools_client.instances, 'SetIamPolicy',
          client.messages.ComputeInstancesSetIamPolicyRequest(
              zoneSetPolicyRequest=client.messages.ZoneSetPolicyRequest(
                  bindings=policy.bindings,
                  etag=policy.etag),
              project=instance_ref.project,
              resource=instance_ref.instance,
              zone=instance_ref.zone))])[0]
