# Copyright 2017 Google Inc. All Rights Reserved.
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
"""`gcloud tasks queues add-iam-policy-binding` command."""

from apitools.base.py import exceptions as apitools_exceptions
from googlecloudsdk.api_lib.tasks import queues
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util
from googlecloudsdk.command_lib.tasks import flags
from googlecloudsdk.command_lib.tasks import parsers


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class AddIamPolicyBinding(base.Command):
  """Add an IAM policy binding to a queue's access policy."""

  detailed_help = iam_util.GetDetailedHelpForAddIamPolicyBinding(
      'queue', 'my-queue', role='roles/cloudtasks.queueAdmin')

  @staticmethod
  def Args(parser):
    flags.AddQueueResourceArg(parser, 'to add the IAM policy binding to')
    flags.AddLocationFlag(parser)
    iam_util.AddArgsForAddIamPolicyBinding(parser)

  def Run(self, args):
    queues_client = queues.Queues()
    queues_messages = queues_client.api.messages
    queue_ref = parsers.ParseQueue(args.queue, args.location)
    try:
      policy = queues_client.GetIamPolicy(queue_ref)
    except apitools_exceptions.HttpNotFoundError:
      # If the error is a 404, no IAM policy exists, so just create a blank one.
      policy = queues_messages.Policy()
    iam_util.AddBindingToIamPolicy(queues_messages.Binding, policy, args.member,
                                   args.role)
    response = queues_client.SetIamPolicy(queue_ref, policy)
    return response
