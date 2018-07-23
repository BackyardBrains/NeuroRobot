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
"""Command to set IAM policy for a resource."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.disks import flags as disks_flags
from googlecloudsdk.command_lib.iam import iam_util


@base.Hidden
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class SetIamPolicy(base.Command):
  """Set the IAM Policy for a Google Compute Engine disk.

  *{command}* replaces the existing IAM policy for a disk, given a disk and a
  file encoded in JSON or YAML that contains the IAM policy. If the given policy
  file specifies an "etag" value, then the replacement will succeed only if the
  policy already in place matches that etag. (An etag obtained via
  `get-iam-policy` will prevent the replacement if the policy for the disk has
  been subsequently updated.) A policy file that does not contain an etag value
  will replace any existing policy for the disk.
  """

  detailed_help = iam_util.GetDetailedHelpForSetIamPolicy('disk', 'my-disk')

  @staticmethod
  def Args(parser):
    SetIamPolicy.disk_arg = disks_flags.MakeDiskArg(plural=False)
    SetIamPolicy.disk_arg.AddArgument(parser,
                                      operation_type='set the IAM policy of')
    compute_flags.AddPolicyFileFlag(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    disk_ref = SetIamPolicy.disk_arg.ResolveAsResource(args, holder.resources)
    policy = iam_util.ParsePolicyFile(args.policy_file, client.messages.Policy)
    # TODO(b/78371568): Construct the ZoneSetPolicyRequest directly
    # out of the parsed policy instead of setting 'bindings' and 'etags'.
    # This current form is required so gcloud won't break while Compute
    # roll outs the breaking change to SetIamPolicy (b/75971480)
    request = client.messages.ComputeDisksSetIamPolicyRequest(
        zoneSetPolicyRequest=client.messages.ZoneSetPolicyRequest(
            bindings=policy.bindings,
            etag=policy.etag),
        resource=disk_ref.disk,
        zone=disk_ref.zone,
        project=disk_ref.project)
    return client.apitools_client.disks.SetIamPolicy(request)
