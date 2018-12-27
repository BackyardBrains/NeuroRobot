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
"""Command to set IAM policy for an instance resource."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.networks.subnets import flags
from googlecloudsdk.command_lib.iam import iam_util


@base.ReleaseTracks(base.ReleaseTrack.ALPHA, base.ReleaseTrack.BETA)
class SetIamPolicy(base.Command):
  """Set the IAM Policy for a Google Compute Engine subnetwork.

  *{command}* sets the Iam Policy associated with a Google Compute Engine
  subnetwork in a project.
  """

  SUBNETWORK_ARG = None

  @staticmethod
  def Args(parser):
    SetIamPolicy.SUBNETWORK_ARG = flags.SubnetworkArgument()
    SetIamPolicy.SUBNETWORK_ARG.AddArgument(
        parser, operation_type='set the IAM Policy of')

    parser.add_argument(
        'policy_file',
        metavar='POLICY_FILE',
        help="""\
        Path to a local JSON or YAML formatted file containing a valid policy.
        """)
    # TODO(b/36050881): fill in detailed help.

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    policy = iam_util.ParsePolicyFile(args.policy_file, client.messages.Policy)

    subnetwork_ref = SetIamPolicy.SUBNETWORK_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(client))

    # TODO(b/78371568): Construct the RegionSetPolicyRequest directly
    # out of the parsed policy instead of setting 'bindings' and 'etags'.
    # This current form is required so gcloud won't break while Compute
    # roll outs the breaking change to SetIamPolicy (b/75971480)

    # TODO(b/36053578): determine how this output should look when empty.

    # SetIamPolicy always returns either an error or the newly set policy.
    # If the policy was just set to the empty policy it returns a valid empty
    # policy (just an etag.)
    # It is not possible to have multiple policies for one resource.
    return client.MakeRequests(
        [(client.apitools_client.subnetworks, 'SetIamPolicy',
          client.messages.ComputeSubnetworksSetIamPolicyRequest(
              regionSetPolicyRequest=client.messages.RegionSetPolicyRequest(
                  bindings=policy.bindings,
                  etag=policy.etag),
              project=subnetwork_ref.project,
              region=subnetwork_ref.region,
              resource=subnetwork_ref.subnetwork))])[0]
