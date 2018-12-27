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
"""Implementation of gcloud genomics variants update.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base


class Update(base.UpdateCommand):
  """Updates variant names."""

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('id',
                        help='The ID of the variant to be updated.')
    parser.add_argument(
        '--names',
        type=arg_parsers.ArgList(min_length=1),
        required=True,
        help='The new variant names replace existing names.')

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      a Variant message
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()

    variant = genomics_messages.Variant(names=args.names,)
    request = genomics_messages.GenomicsVariantsPatchRequest(
        updateMask='names',
        variant=variant,
        variantId=args.id)

    return apitools_client.variants.Patch(request)
