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
"""Command to remove a policy binding from a snapshot."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.snapshots import flags
from googlecloudsdk.command_lib.iam import iam_util


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class RemoveIamPolicyBinding(base.Command):
  r"""Remove a policy binding from a Google Compute Engine snapshot.

  Removes an IAM policy binding from the given snapshot.

  See https://cloud.google.com/iam/docs/managing-policies for details of
  policy role and member types.

  ## EXAMPLES
  The following command will remove an IAM policy binding for the role of
  'roles/editor' for the user 'test-user@gmail.com' on the snapshot
  `my_snapshot`:

    $ {command} my_snapshot \
        --member='user:test-user@gmail.com' \
        --role='roles/editor'
  """

  @staticmethod
  def Args(parser):
    RemoveIamPolicyBinding.snapshot_arg = flags.MakeSnapshotArg()
    RemoveIamPolicyBinding.snapshot_arg.AddArgument(parser)
    iam_util.AddArgsForRemoveIamPolicyBinding(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    snapshot_ref = RemoveIamPolicyBinding.snapshot_arg.ResolveAsResource(
        args, holder.resources)
    get_request = client.messages.ComputeSnapshotsGetIamPolicyRequest(
        resource=snapshot_ref.snapshot, project=snapshot_ref.project)
    policy = client.apitools_client.snapshots.GetIamPolicy(get_request)
    iam_util.RemoveBindingFromIamPolicy(policy, args.member, args.role)
    set_request = client.messages.ComputeSnapshotsSetIamPolicyRequest(
        resource=snapshot_ref.snapshot,
        globalSetPolicyRequest=client.messages.GlobalSetPolicyRequest(
            bindings=policy.bindings,
            etag=policy.etag),
        project=snapshot_ref.project)
    return client.apitools_client.snapshots.SetIamPolicy(set_request)

