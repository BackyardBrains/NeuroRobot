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

"""Cloud Pub/Sub snapshot describe command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.pubsub import snapshots
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.pubsub import util


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class Describe(base.DescribeCommand):
  """This feature is part of an invite-only release of the Cloud Pub/Sub API.

  Describes a Cloud Pub/Sub snapshot.
  This feature is part of an invitation-only release of the underlying
  Cloud Pub/Sub API. The command will generate errors unless you have access to
  this API. This restriction should be relaxed in the near future. Please
  contact cloud-pubsub@google.com with any questions in the meantime.
  """

  @staticmethod
  def Args(parser):
    """Registers flags for this command."""
    parser.add_argument('snapshot', help='snapshot to describe.')

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
        command invocation.

    Returns:
      A serialized object (dict) describing the results of the operation.
      This description fits the Resource described in the ResourceRegistry under
      'pubsub.projects.snapshots'.
    """
    client = snapshots.SnapshotsClient()
    snapshot_ref = util.ParseSnapshot(args.snapshot)
    return client.Get(snapshot_ref)
