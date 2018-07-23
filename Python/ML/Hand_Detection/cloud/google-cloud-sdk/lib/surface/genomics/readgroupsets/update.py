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

"""Implementation of gcloud genomics readgroupsets update.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.api_lib.genomics.exceptions import GenomicsError
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log


class Update(base.UpdateCommand):
  """Updates a readgroupset name and/or referenceSetId.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('id',
                        help='The ID of the read group set to be updated.')
    parser.add_argument('--name',
                        help='The new name of the readgroupset.')
    parser.add_argument('--reference-set-id',
                        help='The new reference set ID of the readgroupset.')

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

    if not (args.name or args.reference_set_id):
      raise GenomicsError('Must specify --name and/or --reference-set-id')

    updated = genomics_messages.ReadGroupSet()
    mask = []
    # TODO(b/26871577): Consider using resource parser here
    if args.name:
      updated.name = args.name
      mask.append('name')
    if args.reference_set_id:
      updated.referenceSetId = args.reference_set_id
      mask.append('referenceSetId')

    request = genomics_messages.GenomicsReadgroupsetsPatchRequest(
        readGroupSet=updated,
        readGroupSetId=str(args.id),
        updateMask=','.join(mask)
    )

    result = apitools_client.readgroupsets.Patch(request)
    name = str(result.id)
    if result.name:
      name += ', name: {0}'.format(result.name)
    if result.referenceSetId:
      name += ', referenceSetId: {0}'.format(result.referenceSetId)
    log.UpdatedResource(name, kind='readgroupset')
    return result
