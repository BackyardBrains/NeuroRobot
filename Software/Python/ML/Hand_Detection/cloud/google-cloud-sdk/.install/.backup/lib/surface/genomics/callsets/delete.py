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

"""Implementation of gcloud genomics callsets delete.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.api_lib.genomics.exceptions import GenomicsError
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log
from googlecloudsdk.core.console import console_io


class Delete(base.DeleteCommand):
  """Deletes a call set.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('id',
                        help='The ID of the call set to be deleted.')

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
    # Look it up first so that we can display the name
    existing_cs = genomics_util.GetCallSet(args.id)
    prompt_message = (
        'Deleting call set {0} ({1}) will delete all objects in the '
        'call set.').format(existing_cs.id, existing_cs.name)
    if not console_io.PromptContinue(message=prompt_message):
      raise GenomicsError('Deletion aborted by user.')
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()
    call_set = genomics_messages.GenomicsCallsetsDeleteRequest(
        callSetId=args.id,
    )

    apitools_client.callsets.Delete(call_set)
    log.DeletedResource('{0} ({1})'.format(existing_cs.id,
                                           existing_cs.name))
