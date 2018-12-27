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
"""Command to add an IAM policy binding to an image resource."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.images import flags as images_flags
from googlecloudsdk.command_lib.iam import iam_util


@base.Hidden
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class AddIamPolicyBinding(base.Command):
  """Add an IAM policy binding to a Google Compute Engine image.

  *{command}* adds an IAM policy binding to a Google Compute Engine
  image's access policy.
  """
  detailed_help = iam_util.GetDetailedHelpForAddIamPolicyBinding(
      'image', 'my-image', role='roles/compute.securityAdmin',
      use_an=True)

  @staticmethod
  def Args(parser):
    AddIamPolicyBinding.disk_image_arg = images_flags.MakeDiskImageArg(
        plural=False)
    AddIamPolicyBinding.disk_image_arg.AddArgument(
        parser, operation_type='add the IAM policy binding to')
    iam_util.AddArgsForAddIamPolicyBinding(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    image_ref = AddIamPolicyBinding.disk_image_arg.ResolveAsResource(
        args, holder.resources)
    get_request = client.messages.ComputeImagesGetIamPolicyRequest(
        resource=image_ref.image, project=image_ref.project)
    policy = client.apitools_client.images.GetIamPolicy(get_request)
    iam_util.AddBindingToIamPolicy(client.messages.Binding, policy, args.member,
                                   args.role)
    # TODO(b/78371568): Construct the GlobalSetPolicyRequest directly
    # out of the parsed policy.
    set_request = client.messages.ComputeImagesSetIamPolicyRequest(
        globalSetPolicyRequest=client.messages.GlobalSetPolicyRequest(
            bindings=policy.bindings,
            etag=policy.etag),
        resource=image_ref.image,
        project=image_ref.project)
    return client.apitools_client.images.SetIamPolicy(set_request)
