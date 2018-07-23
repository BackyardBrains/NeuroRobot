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
"""Set the IAM policy for an authority."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.container.binauthz import iam
from googlecloudsdk.api_lib.container.binauthz import util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util


class SetIamPolicy(base.Command):
  """Set the IAM policy for an authority.

  See https://cloud.google.com/iam/docs/managing-policies for details of
  the policy file format and contents.

  ## EXAMPLES
  The following command will read an IAM policy defined in a JSON file
  'iam_policy.json' and set it for the authority `my_authority`:

    $ {command} my_authority iam_policy.json
  """
  # The above text is based on output of
  # iam_util.GetDetailedHelpForSetIamPolicy.

  @staticmethod
  def Args(parser):
    # TODO(b/77985971): Make this a resource.
    parser.add_argument('authority_name', help=('The name of the authority '
                                                'whose IAM policy will be '
                                                'updated.'))
    parser.add_argument('policy_file', help=('The JSON or YAML '
                                             'file containing the IAM policy.'))

  def Run(self, args):
    client = iam.Client()
    authority_ref = util.GetAuthorityRef(args.authority_name)

    policy, _ = iam_util.ParseYamlOrJsonPolicyFile(args.policy_file,
                                                   client.messages.IamPolicy)

    result = client.Set(authority_ref, policy)
    iam_util.LogSetIamPolicy(authority_ref.Name(), 'authority')
    return result
