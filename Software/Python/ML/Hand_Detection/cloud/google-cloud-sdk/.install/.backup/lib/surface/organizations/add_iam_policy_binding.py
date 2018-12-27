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

"""Command to add IAM policy binding for an organization."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.util import http_retry
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util
from googlecloudsdk.command_lib.organizations import flags
from googlecloudsdk.command_lib.organizations import orgs_base
from googlecloudsdk.command_lib.resource_manager import completers
import six.moves.http_client


@base.ReleaseTracks(
    base.ReleaseTrack.GA, base.ReleaseTrack.BETA, base.ReleaseTrack.ALPHA)
class AddIamPolicyBinding(orgs_base.OrganizationCommand):
  """Add IAM policy binding for an organization.

  Adds a policy binding to the IAM policy of an organization,
  given an organization ID and the binding.
  """

  detailed_help = iam_util.GetDetailedHelpForAddIamPolicyBinding('organization',
                                                                 '123456789')

  @staticmethod
  def Args(parser):
    flags.IdArg('to which you want to add a binding').AddToParser(parser)
    iam_util.AddArgsForAddIamPolicyBinding(
        parser, completer=completers.OrganizationsIamRolesCompleter)

  @http_retry.RetryOnHttpStatus(six.moves.http_client.CONFLICT)
  def Run(self, args):
    messages = self.OrganizationsMessages()

    get_policy_request = (
        messages.CloudresourcemanagerOrganizationsGetIamPolicyRequest(
            organizationsId=args.id,
            getIamPolicyRequest=messages.GetIamPolicyRequest()))
    policy = self.OrganizationsClient().GetIamPolicy(get_policy_request)

    iam_util.AddBindingToIamPolicy(
        messages.Binding, policy, args.member, args.role)

    set_policy_request = (
        messages.CloudresourcemanagerOrganizationsSetIamPolicyRequest(
            organizationsId=args.id,
            setIamPolicyRequest=messages.SetIamPolicyRequest(policy=policy)))

    return self.OrganizationsClient().SetIamPolicy(set_policy_request)
