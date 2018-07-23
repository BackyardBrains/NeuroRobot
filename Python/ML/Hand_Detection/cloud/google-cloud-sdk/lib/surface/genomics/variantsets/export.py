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
"""Implementation of gcloud genomics variantsets export.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base


class Export(base.Command):
  """Exports data from a variant set to an external destination.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument(
        'id',
        type=str,
        help='The ID of the variant set to export.')
    parser.add_argument(
        'table',
        type=str,
        help=('The BigQuery table to which data is exported.  If this table '
              'does not exist, it will be created.  If it already exists, it '
              'will be overwritten.'))
    parser.add_argument(
        '--call-set-ids',
        type=arg_parsers.ArgList(),
        help=('If provided, only variant call information '
              'from the specified call sets will be exported. '
              'By default all variant call sets are exported. '))
    # TODO(b/36057052) Use resource parser for beta b/22357346
    parser.add_argument(
        '--bigquery-project',
        type=str,
        help=('The Google Cloud project ID that owns the destination BigQuery '
              'dataset.  The caller must have WRITE access to this project.  '
              'This project will also own the resulting export job.'
              'If not supplied, defaults to the gcloud project ID.'))
    parser.add_argument(
        '--bigquery-dataset',
        type=str,
        required=True,
        help=('The BigQuery dataset to which data is exported.  This dataset '
              'must already exist.  Note that this is distinct from the '
              'Genomics concept of "dataset."'))

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Raises:
      HttpException: An http error response was received while executing api
          request.
    Returns:
      an ExportVariantSetResponse
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()
    enum = genomics_messages.ExportVariantSetRequest.FormatValueValuesEnum
    call_set_ids = args.call_set_ids if args.call_set_ids else []
    project_id = args.bigquery_project
    if not project_id:
      project_id = genomics_util.GetProjectId()
    request = genomics_messages.GenomicsVariantsetsExportRequest(
        variantSetId=args.id,
        exportVariantSetRequest=genomics_messages.ExportVariantSetRequest(
            callSetIds=call_set_ids,
            projectId=project_id,
            format=enum.FORMAT_BIGQUERY,
            bigqueryDataset=args.bigquery_dataset,
            bigqueryTable=args.table))

    return apitools_client.variantsets.Export(request)
