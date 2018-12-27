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

"""Implementation of gcloud genomics callsets create.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base
from googlecloudsdk.core import log


class Create(base.CreateCommand):
  """Creates a call set with a specified name.

  A call set is a collection of variant calls, typically for one sample.
  """

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command.

    Args:
      parser: An argparse parser that you can use to add arguments that go
          on the command line after this command. Positional arguments are
          allowed.
    """
    parser.add_argument('--name',
                        help='The name of the call set being created.',
                        required=True)
    parser.add_argument(
        '--variant-set-id',
        required=True,
        help='Variant set that this call set belongs to.')
    # TODO(b/36053574): Add the info command.

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: argparse.Namespace, All the arguments that were provided to this
        command invocation.

    Raises:
      HttpException: An http error response was received while executing api
          request.
    Returns:
      None
    """
    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()
    call_set = genomics_messages.CallSet(
        name=args.name,
        variantSetIds=[args.variant_set_id],
    )

    result = apitools_client.callsets.Create(call_set)
    log.CreatedResource('{0}, id: {1}'.format(result.name, result.id),
                        kind='call set')
    return result
