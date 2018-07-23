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
"""Implementation of gcloud genomics variants import.
"""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.util.apis import arg_utils


def _GetFormatEnum():
  """Get Enum for Variant File Formats."""
  genomics_messages = genomics_util.GetGenomicsMessages()
  return genomics_messages.ImportVariantsRequest.FormatValueValuesEnum


_FILE_FORMAT_MAPPER = arg_utils.ChoiceEnumMapper(
    '--file-format',
    _GetFormatEnum(),
    custom_mappings={
        'FORMAT_COMPLETE_GENOMICS': 'complete-genomics', 'FORMAT_VCF': 'vcf'},
    default='vcf',
    help_str='Set the file format of the `--source-uris`.')


class Import(base.Command):
  """Imports variants into Google Genomics.

  Import variants from VCF or MasterVar files that are in Google Cloud Storage.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('--variantset-id',
                        type=str,
                        required=True,
                        help='The ID of the destination variant set.')
    parser.add_argument('--source-uris',
                        type=arg_parsers.ArgList(min_length=1),
                        required=True,
                        help=('A comma-delimited list of URI patterns '
                              'referencing existing VCF or MasterVar files in '
                              'Google Cloud Storage.'))
    parser.add_argument('--info-merge-config',
                        type=arg_parsers.ArgDict(min_length=1),
                        required=False,
                        help=('A mapping between VCF INFO field keys and the '
                              'operations to be performed on them. '
                              'Valid operations include: '
                              'IGNORE_NEW - By default, variant info fields '
                              'are persisted if the variant does not '
                              'yet exist in the variant set.  If the variant '
                              'is equivalent to a variant already in the '
                              'variant set, the incoming variant\'s info field '
                              'is ignored in favor of that of the already '
                              'persisted variant. '
                              'MOVE_TO_CALLS - Removes an info field from '
                              'the incoming variant and persists this info '
                              'field in each of the incoming variant\'s '
                              'calls.'))
    parser.add_argument('--normalize-reference-names',
                        dest='normalize_reference_names',
                        action='store_true',
                        help=('Convert reference names to the canonical '
                              'representation. hg19 haplotypes (those '
                              'reference names containing "_hap") are not '
                              'modified in any way. All other reference names '
                              'are modified according to the following rules: '
                              'The reference name is capitalized. '
                              'The "chr" prefix is dropped for all autosomes '
                              'and sex chromsomes. For example "chr17" '
                              'becomes "17" and "chrX" becomes "X". All '
                              'mitochondrial chromosomes ("chrM", "chrMT", '
                              'etc) become "MT".'))
    _FILE_FORMAT_MAPPER.choice_arg.AddToParser(parser)
    parser.set_defaults(normalize_referecne_names=False)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      an ImportVariantsResponse message
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    file_format = _FILE_FORMAT_MAPPER.GetEnumForChoice(args.file_format)
    imc = genomics_messages.ImportVariantsRequest.InfoMergeConfigValue
    ops_enum = imc.AdditionalProperty.ValueValueValuesEnum
    info_merge_config = None
    if args.info_merge_config is not None:
      additional_properties = []
      for k, v in sorted(args.info_merge_config.items()):
        op = ops_enum.INFO_MERGE_OPERATION_UNSPECIFIED
        if v == 'IGNORE_NEW':
          op = ops_enum.IGNORE_NEW
        elif v == 'MOVE_TO_CALLS':
          op = ops_enum.MOVE_TO_CALLS
        additional_properties.append(imc.AdditionalProperty(key=k, value=op))
      info_merge_config = imc(additionalProperties=additional_properties)

    request = genomics_messages.ImportVariantsRequest(
        variantSetId=args.variantset_id,
        sourceUris=args.source_uris,
        format=file_format,
        normalizeReferenceNames=args.normalize_reference_names,
        infoMergeConfig=info_merge_config)

    return apitools_client.variants.Import(request)
