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
"""`gcloud tasks queues set-iam-policy` command."""

from googlecloudsdk.api_lib.tasks import queues
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util
from googlecloudsdk.command_lib.tasks import flags
from googlecloudsdk.command_lib.tasks import parsers
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class SetIamPolicy(base.Command):
  """Set the IAM policy for a queue.

  This command replaces the existing IAM policy for a queue, given a queue and a
  file encoded in JSON or YAML that contains the IAM policy. If the given policy
  file specifies an "etag" value, then the replacement will succeed only if the
  policy already in place matches that etag. (An etag obtained via
  `get-iam-policy` will prevent the replacement if the policy for the queue has
  been subsequently updated.) A policy file that does not contain an etag value
  will replace any existing policy for the queue.
  """

  detailed_help = iam_util.GetDetailedHelpForSetIamPolicy('queue', 'my-queue')

  @staticmethod
  def Args(parser):
    flags.AddQueueResourceArg(parser, 'to set the IAM policy for')
    flags.AddLocationFlag(parser)
    flags.AddPolicyFileFlag(parser)

  def Run(self, args):
    queues_client = queues.Queues()
    queues_messages = queues_client.api.messages
    queue_ref = parsers.ParseQueue(args.queue, args.location)
    self.context['iam-messages'] = queues_messages
    policy = iam_util.ParsePolicyFile(args.policy_file, queues_messages.Policy)
    response = queues_client.SetIamPolicy(queue_ref, policy)
    log.status.Print('Set IAM policy for queue [{}].'.format(queue_ref.Name()))
    return response
