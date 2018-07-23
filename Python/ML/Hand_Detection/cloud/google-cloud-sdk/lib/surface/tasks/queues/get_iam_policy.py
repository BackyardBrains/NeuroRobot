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
"""`gcloud tasks queues get-iam-policy` command."""

from googlecloudsdk.api_lib.tasks import queues
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.tasks import flags
from googlecloudsdk.command_lib.tasks import parsers


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class GetIamPolicy(base.ListCommand):
  """Get the IAM policy for a queue.

  This command gets the IAM policy for a queue. If formatted as JSON, the output
  can be edited and used as a policy file for `set-iam-policy`. The output
  includes an "etag" field identifying the version emitted and allowing
  detection of concurrent policy updates; see `set-iam-policy` for
  additional details.
  """

  @staticmethod
  def Args(parser):
    flags.AddQueueResourceArg(parser, 'to get the IAM policy for')
    flags.AddLocationFlag(parser)

  def Run(self, args):
    queues_client = queues.Queues()
    queue_ref = parsers.ParseQueue(args.queue, args.location)
    return queues_client.GetIamPolicy(queue_ref)
