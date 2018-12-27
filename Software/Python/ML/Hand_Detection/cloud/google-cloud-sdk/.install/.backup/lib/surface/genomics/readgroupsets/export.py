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

"""Implementation of gcloud genomics readgroupsets export.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions

from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import exceptions as core_exceptions


class Export(base.Command):
  """Exports a read group set to a BAM file in cloud storage.

  Exports a read group set, optionally restricted by reference name, to a BAM
  file in a provided Google Cloud Storage object. This command yields an
  asynchronous Operation resource which tracks the completion of this task. See
  [](https://cloud.google.com/genomics/managing-reads for more details)
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument(
        'read_group_set_id',
        type=str,
        help='The ID of the read group set to export.')
    parser.add_argument(
        '--export-uri',
        type=str,
        required=True,
        help=('Google Cloud Storage URI to which the BAM file '
              '(https://samtools.github.io/hts-specs/SAMv1.pdf) should be '
              'exported.'))
    parser.add_argument(
        '--reference-names',
        type=arg_parsers.ArgList(),
        default=[],
        help=('Comma separated list of reference names to be exported from the '
              'given read group set. Provide * to export unmapped reads. By '
              'default, all reads are exported.'))

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      an Operation message which tracks the asynchronous export
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    try:
      return apitools_client.readgroupsets.Export(
          genomics_messages.GenomicsReadgroupsetsExportRequest(
              readGroupSetId=args.read_group_set_id,
              exportReadGroupSetRequest=
              genomics_messages.ExportReadGroupSetRequest(
                  projectId=genomics_util.GetProjectId(),
                  exportUri=args.export_uri,
                  referenceNames=args.reference_names)
          ))
    except apitools_exceptions.HttpError as error:
      # Map our error messages (JSON API camelCased) back into flag names.
      msg = (exceptions.HttpException(error).payload.status_message
             .replace('exportUri', '--export-uri')
             .replace('referenceNames', '--reference-names'))
      core_exceptions.reraise(exceptions.HttpException(msg))
