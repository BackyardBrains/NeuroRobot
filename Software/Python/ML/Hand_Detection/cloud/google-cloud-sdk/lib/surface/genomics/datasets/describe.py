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
"""Implementation of gcloud genomics datasets describe.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base
from googlecloudsdk.core import resources


class Describe(base.DescribeCommand):
  """Returns details about a dataset.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('id',
                        type=str,
                        help='The ID of the dataset to be described.')

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      a Dataset message
    """
    apitools_client = genomics_util.GetGenomicsClient()
    dataset_resource = resources.REGISTRY.Parse(
        args.id, collection='genomics.datasets')

    return apitools_client.datasets.Get(
        apitools_client.MESSAGES_MODULE.GenomicsDatasetsGetRequest(
            datasetId=dataset_resource.datasetId))
