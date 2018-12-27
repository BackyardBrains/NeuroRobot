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
"""Implementation of gcloud genomics operations describe.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base


class Describe(base.DescribeCommand):
  """Returns details about an operation.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('name',
                        type=str,
                        help=('The name of the operation to be described.'))

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      a Operation message
    """
    name, v2 = genomics_util.CanonicalizeOperationName(args.name)
    if v2:
      apitools_client = genomics_util.GetGenomicsClient('v2alpha1')
      genomics_messages = genomics_util.GetGenomicsMessages('v2alpha1')
      return apitools_client.projects_operations.Get(
          genomics_messages.GenomicsProjectsOperationsGetRequest(name=name))

    apitools_client = genomics_util.GetGenomicsClient()
    genomics_messages = genomics_util.GetGenomicsMessages()
    return apitools_client.operations.Get(
        genomics_messages.GenomicsOperationsGetRequest(name=name))
