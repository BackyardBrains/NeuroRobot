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

"""Command to remove IAM policy binding for a resource."""

from __future__ import absolute_import
from __future__ import unicode_literals


from googlecloudsdk.api_lib.cloudresourcemanager import projects_api
from googlecloudsdk.api_lib.util import http_retry
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util
from googlecloudsdk.command_lib.projects import flags
from googlecloudsdk.command_lib.projects import util as command_lib_util
from googlecloudsdk.command_lib.resource_manager import completers
import six.moves.http_client


class RemoveIamPolicyBinding(base.Command):
  """Remove IAM policy binding for a project.

  Removes a policy binding to the IAM policy of a project, given a project ID
  and the binding.
  """

  detailed_help = iam_util.GetDetailedHelpForRemoveIamPolicyBinding(
      'project', 'example-project-id-1')

  @staticmethod
  def Args(parser):
    flags.GetProjectFlag('remove IAM policy binding from').AddToParser(parser)
    iam_util.AddArgsForRemoveIamPolicyBinding(
        parser, completer=completers.ProjectsIamRolesCompleter)

  @http_retry.RetryOnHttpStatus(six.moves.http_client.CONFLICT)
  def Run(self, args):
    project_ref = command_lib_util.ParseProject(args.id)
    return projects_api.RemoveIamPolicyBinding(project_ref,
                                               args.member, args.role)
