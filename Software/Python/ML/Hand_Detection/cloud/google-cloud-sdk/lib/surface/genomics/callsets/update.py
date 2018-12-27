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

"""Implementation of gcloud genomics callsets update.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log


class Update(base.UpdateCommand):
  """Updates a call set name.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('id',
                        help='The ID of the call set to be updated.')
    parser.add_argument('--name',
                        help='The new name of the call set.',
                        required=True)

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

    request = genomics_messages.GenomicsCallsetsPatchRequest(
        callSet=genomics_messages.CallSet(
            id=args.id,
            name=args.name,
            # Can't construct a callset without the variant id set, but
            # actually setting the variant id would not do anything, so
            # use a dummy value. See b/22818510.
            variantSetIds=['123'],
        ),
        callSetId=args.id,
    )

    result = apitools_client.callsets.Patch(request)
    log.UpdatedResource('{0}, id: {1}'.format(result.name, result.id),
                        kind='call set')
    return result
