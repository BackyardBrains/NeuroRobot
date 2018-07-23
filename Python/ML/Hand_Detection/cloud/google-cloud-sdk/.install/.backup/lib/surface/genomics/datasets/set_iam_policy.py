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

"""Implementation of gcloud genomics datasets set-iam-policy.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iam import iam_util
from googlecloudsdk.core import resources


class SetIamPolicy(base.Command):
  """Set IAM policy for a dataset.

  This command sets the IAM policy for a dataset, given a dataset ID and a
  file that contains the JSON encoded IAM policy.
  """

  detailed_help = iam_util.GetDetailedHelpForSetIamPolicy(
      'dataset', '1000',
      """See https://cloud.google.com/genomics/v1/access-control for details on
          managing access control on Genomics datasets.""")

  @staticmethod
  def Args(parser):
    parser.add_argument('id', type=str,
                        help='The ID of the dataset.')
    parser.add_argument('policy_file', help='JSON file with the IAM policy')

  def Run(self, args):
    apitools_client = genomics_util.GetGenomicsClient()
    messages = genomics_util.GetGenomicsMessages()

    dataset_resource = resources.REGISTRY.Parse(
        args.id, collection='genomics.datasets')

    policy = iam_util.ParsePolicyFile(args.policy_file, messages.Policy)

    policy_request = messages.GenomicsDatasetsSetIamPolicyRequest(
        resource='datasets/{0}'.format(dataset_resource.Name()),
        setIamPolicyRequest=messages.SetIamPolicyRequest(policy=policy),
    )
    result = apitools_client.datasets.SetIamPolicy(policy_request)
    iam_util.LogSetIamPolicy(dataset_resource.Name(), 'dataset')
    return result
