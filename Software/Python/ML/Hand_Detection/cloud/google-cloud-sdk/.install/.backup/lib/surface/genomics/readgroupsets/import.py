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

"""Implementation of gcloud genomics readgroupsets import.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions

from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.api_lib.genomics.exceptions import GenomicsError
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import exceptions as core_exceptions


class Import(base.Command):
  """Imports read group sets into a dataset.

  Imports read group sets from a set of BAM files in Google Cloud Storage. See
  [](https://cloud.google.com/genomics/managing-reads for more details)
  """
  detailed_help = {
      'EXAMPLES': """\
          Import a single BAM file and associate with the GRCh38 reference set:

            $ {command} --dataset-id 123 --reference-set-id "EMud_c37lKPXTQ" --source-uris "gs://mybucket/reads.bam"

          Import a single sample which is sharded across multiple BAM files:

            $ {command} --dataset-id 123 --partition-strategy MERGE_ALL --source-uris "gs://mybucket/chr?.bam,gs://mybucket/mt.bam"
          """,
  }

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument(
        '--source-uris',
        type=arg_parsers.ArgList(),
        required=True,
        help='Comma separated list of Google Cloud Storage URIs for BAM files '
        '(https://samtools.github.io/hts-specs/SAMv1.pdf) to be imported.')
    parser.add_argument(
        '--dataset-id',
        required=True,
        help=
        'The ID of the dataset the imported read group sets will belong to.')
    parser.add_argument(
        '--reference-set-id',
        help='The reference set ID to associate with the imported read group '
        'sets. The reference headers in the provided BAM files will be '
        'validated against this ID. The reference set ID can be used '
        'by consumers of your imported read group sets for more robust '
        'reference genome comparison.')
    parser.add_argument(
        '--partition-strategy',
        help='One of "PER_FILE_PER_SAMPLE" or "MERGE_ALL". The partition '
        'strategy describes how read groups from the provided files are '
        'partitioned into read group sets. In general, use PER_FILE_PER_SAMPLE '
        'when importing multiple samples from multiple files and use MERGE_ALL '
        'when importing a single sample from multiple files. Defaults to '
        'PER_FILE_PER_SAMPLE')

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      an Operation message which tracks the asynchronous import
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    if not args.source_uris:
      raise GenomicsError('at least one value is required for --source-uris')

    partition_enum = (genomics_messages.ImportReadGroupSetsRequest
                      .PartitionStrategyValueValuesEnum)
    partition_strat = None
    if args.partition_strategy:
      if args.partition_strategy not in partition_enum.to_dict():
        raise GenomicsError(
            '--partition-strategy must be one of {0}; received: {1}'
            .format(sorted(partition_enum.names()), args.partition_strategy))
      partition_strat = partition_enum.lookup_by_name(args.partition_strategy)

    try:
      return apitools_client.readgroupsets.Import(
          genomics_messages.ImportReadGroupSetsRequest(
              datasetId=args.dataset_id,
              sourceUris=args.source_uris,
              referenceSetId=args.reference_set_id,
              partitionStrategy=partition_strat,
          ))
    except apitools_exceptions.HttpError as error:
      # Map our error messages (JSON API camelCased) back into flag names.
      msg = (exceptions.HttpException(error).payload.status_message
             .replace('datasetId', '--dataset-id')
             .replace('partitionStrategy', '--partition-strategy')
             .replace('sourceUris', '--source-uris')
             .replace('referenceSetId', '--reference-set-id'))
      core_exceptions.reraise(exceptions.HttpException(msg))
