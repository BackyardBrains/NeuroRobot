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

"""Implementation of gcloud genomics variantsets delete.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.api_lib.genomics.exceptions import GenomicsError
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log
from googlecloudsdk.core.console import console_io


class Delete(base.DeleteCommand):
  """Deletes a variant set.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('variant_set_id',
                        help='The ID of the variant set to be deleted.')

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Raises:
      HttpException: An http error response was received while executing api
          request.
      GenomicsError: if canceled by the user.
    Returns:
      None
    """

    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    get_request = genomics_messages.GenomicsVariantsetsGetRequest(
        variantSetId=str(args.variant_set_id))

    variant_set = apitools_client.variantsets.Get(get_request)

    prompt_message = (
        'Deleting variant set {0}: "{1}" will also delete all its contents '
        '(variants, callsets, and calls).').format(args.variant_set_id,
                                                   variant_set.name)

    if not console_io.PromptContinue(message=prompt_message):
      raise GenomicsError('Deletion aborted by user.')

    req = genomics_messages.GenomicsVariantsetsDeleteRequest(
        variantSetId=args.variant_set_id,)

    ret = apitools_client.variantsets.Delete(req)
    log.DeletedResource('{0}: "{1}"'.format(args.variant_set_id,
                                            variant_set.name))
    return ret
