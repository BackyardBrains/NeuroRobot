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

"""Command for removing IAM policies for service accounts."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.iam import util
from googlecloudsdk.api_lib.util import http_retry
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util

import six.moves.http_client


class RemoveIamPolicyBinding(base.Command):
  """Remove an IAM policy binding from a service account.

  This command removes a policy binding to the IAM policy of a service account,
  given an IAM_ACCOUNT and the binding.
  """

  detailed_help = iam_util.GetDetailedHelpForRemoveIamPolicyBinding(
      'service account', 'my-iam-account@somedomain.com')
  detailed_help['DESCRIPTION'] += '\n\n' + (
      iam_util.GetHintForServiceAccountResource(
          'remove a policy binding from'))

  @staticmethod
  def Args(parser):
    iam_util.AddServiceAccountNameArg(
        parser,
        action='to remove the policy binding from')
    iam_util.AddArgsForRemoveIamPolicyBinding(parser)

  @http_retry.RetryOnHttpStatus(six.moves.http_client.CONFLICT)
  def Run(self, args):
    client, messages = util.GetClientAndMessages()
    policy = client.projects_serviceAccounts.GetIamPolicy(
        messages.IamProjectsServiceAccountsGetIamPolicyRequest(
            resource=iam_util.EmailToAccountResourceName(args.service_account)))

    iam_util.RemoveBindingFromIamPolicy(policy, args.member, args.role)

    return client.projects_serviceAccounts.SetIamPolicy(
        messages.IamProjectsServiceAccountsSetIamPolicyRequest(
            resource=iam_util.EmailToAccountResourceName(args.service_account),
            setIamPolicyRequest=messages.SetIamPolicyRequest(
                policy=policy)))
