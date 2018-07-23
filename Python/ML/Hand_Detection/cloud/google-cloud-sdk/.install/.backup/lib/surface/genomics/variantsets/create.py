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

"""Implementation of gcloud genomics variant sets create.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log


class Create(base.CreateCommand):
  """Creates a variant set belonging to a specified dataset.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument(
        '--name', type=str,
        help='The user-defined name of the variant set. '
        'Name does not uniquely identify a variant set. '
        'It is for descriptive purposes only.')
    parser.add_argument(
        '--dataset-id',
        type=str,
        help='The ID of the dataset the variant set will belong to.',
        required=True)
    parser.add_argument('--description',
                        type=str,
                        help='A description of the variant set.')
    parser.add_argument(
        '--reference-set-id',
        type=str, help='The reference set the variant set will be associated '
        'with. When variants are later added to this variant set, the API '
        'enforces consistency with this reference set.')

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Raises:
      HttpException: An http error response was received while executing api
          request.
    Returns:
      None
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    variantset = genomics_messages.VariantSet(
        datasetId=args.dataset_id,
        referenceSetId=args.reference_set_id,
        name=args.name,
        description=args.description)

    result = apitools_client.variantsets.Create(variantset)
    log.CreatedResource('{0}, id: {1}'.format(result.name, result.id),
                        kind='variant set',
                        details='belonging to dataset [id: {0}]'.format(
                            result.datasetId))
    return result
