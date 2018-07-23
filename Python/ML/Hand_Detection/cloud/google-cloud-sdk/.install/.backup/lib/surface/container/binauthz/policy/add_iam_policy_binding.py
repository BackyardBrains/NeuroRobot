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
"""Command to add an IAM policy binding for a Binary Authorization policy."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.container.binauthz import iam
from googlecloudsdk.api_lib.container.binauthz import util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util


class AddIamPolicyBinding(base.Command):
  r"""Add IAM policy binding to a Binary Authorization policy.

  See https://cloud.google.com/iam/docs/managing-policies for details of
  policy role and member types.

  ## EXAMPLES
  The following command will add an IAM policy binding for the role of
  'roles/binaryauthorization.attestationAuthoritiesEditor' for the user
  'test-user@gmail.com' on the current project's Binary Authorization policy:

    $ {command} \
        --member='user:test-user@gmail.com' \
        --role='roles/binaryauthorization.attestationAuthoritiesEditor'
  """
  # The above text based on output from
  # iam_util.GetDetailedHelpForAddIamPolicyBinding.

  @staticmethod
  def Args(parser):
    iam_util.AddArgsForAddIamPolicyBinding(parser)

  def Run(self, args):
    return iam.Client().AddBinding(util.GetPolicyRef(), args.member, args.role)
