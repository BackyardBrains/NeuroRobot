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
"""`gcloud tasks queues remove-iam-policy-binding` command."""

from googlecloudsdk.api_lib.tasks import queues
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util
from googlecloudsdk.command_lib.tasks import flags
from googlecloudsdk.command_lib.tasks import parsers
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class RemoveIamPolicyBinding(base.Command):
  """Remove an IAM policy binding from a queue's access policy."""

  detailed_help = iam_util.GetDetailedHelpForRemoveIamPolicyBinding(
      'queue', 'my-queue', role='roles/cloudtasks.queueAdmin')

  @staticmethod
  def Args(parser):
    flags.AddQueueResourceArg(parser, 'to remove the IAM policy binding from')
    flags.AddLocationFlag(parser)
    iam_util.AddArgsForRemoveIamPolicyBinding(parser)

  def Run(self, args):
    queues_client = queues.Queues()
    queue_ref = parsers.ParseQueue(args.queue, args.location)
    policy = queues_client.GetIamPolicy(queue_ref)
    iam_util.RemoveBindingFromIamPolicy(policy, args.member, args.role)
    response = queues_client.SetIamPolicy(queue_ref, policy)
    log.status.Print('Updated IAM policy for queue [{}].'.format(
        queue_ref.Name()))
    return response
