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
from googlecloudsdk.command_lib.compute.images import flags
from googlecloudsdk.command_lib.iam import iam_util


@base.Hidden
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class SetIamPolicy(base.Command):
  """Set the IAM Policy for a Google Compute Engine disk image.

  *{command}* replaces the existing IAM policy for a disk image, given an image
  and a file encoded in JSON or YAML that contains the IAM policy. If the given
  policy file specifies an "etag" value, then the replacement will succeed only
  if the policy already in place matches that etag. (An etag obtained via
  `get-iam-policy` will prevent the replacement if the policy for the image has
  been subsequently updated.) A policy file that does not contain an etag value
  will replace any existing policy for the image.
  """

  detailed_help = iam_util.GetDetailedHelpForSetIamPolicy('disk image',
                                                          'my-image')

  @staticmethod
  def Args(parser):
    SetIamPolicy.disk_image_arg = flags.MakeDiskImageArg(plural=False)
    SetIamPolicy.disk_image_arg.AddArgument(
        parser, operation_type='set the IAM policy of')
    compute_flags.AddPolicyFileFlag(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    image_ref = SetIamPolicy.disk_image_arg.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(client))
    policy = iam_util.ParsePolicyFile(args.policy_file, client.messages.Policy)

    # TODO(b/78371568): Construct the GlobalSetPolicyRequest directly
    # out of the parsed policy instead of setting 'bindings' and 'etags'.
    # This current form is required so gcloud won't break while Compute
    # roll outs the breaking change to SetIamPolicy (b/75971480)
    request = client.messages.ComputeImagesSetIamPolicyRequest(
        globalSetPolicyRequest=client.messages.GlobalSetPolicyRequest(
            bindings=policy.bindings,
            etag=policy.etag),
        resource=image_ref.image, project=image_ref.project)
    return client.apitools_client.images.SetIamPolicy(request)
