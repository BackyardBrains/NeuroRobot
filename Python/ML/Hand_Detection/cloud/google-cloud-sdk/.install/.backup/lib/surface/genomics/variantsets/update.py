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
"""Implementation of gcloud genomics variantsets update.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log


class Update(base.UpdateCommand):
  """Updates a variant set name or description.
  """

  @staticmethod
  def Args(parser):
    parser.add_argument('id', help='The ID of the variant set to update.')
    parser.add_argument('--name', help='The new name of the variant set.')
    parser.add_argument('--description',
                        help='The new description of the variant set.')
    parser.display_info.AddFormat(None)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Raises:
      HttpException: An http error response was received while executing api
          request.
    Returns:
      a VariantSet whose id matches args.id.
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    updated = genomics_messages.VariantSet()
    mask = []

    if args.name:
      updated.name = args.name
      mask.append('name')
    if args.description:
      updated.description = args.description
      mask.append('description')

    request = genomics_messages.GenomicsVariantsetsPatchRequest(
        variantSetId=args.id,
        variantSet=updated,
        updateMask=','.join(mask))

    variantset = apitools_client.variantsets.Patch(request)
    log.status.Print('Updated variant set {0}, name: {1}, description: {2}'
                     .format(variantset.id, variantset.name,
                             variantset.description))
    return variantset
