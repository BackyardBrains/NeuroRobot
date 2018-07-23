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

"""call sets list command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import list_pager

from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base


class List(base.ListCommand):
  """List genomics call sets in a project.

  Prints a table with summary information on call sets in the project.
  """

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command.

    Args:
      parser: An argparse parser that you can use to add arguments that go
          on the command line after this command. Positional arguments are
          allowed.
    """
    parser.add_argument(
        'variant_set_ids',
        nargs='+',
        help="""Restrict the query to call sets within the given variant sets.
             At least one ID must be provided.""")

    parser.add_argument(
        '--name',
        help="""Only return call sets for which a substring of the
             name matches this string.""")

    parser.display_info.AddFormat("""
          table(
            id,
            name,
            variantSetIds.list()
          )
        """)

  def Run(self, args):
    """Run 'callsets list'.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Returns:
      The list of callsets matching the given variant set ids.
    """
    apitools_client = genomics_util.GetGenomicsClient()
    req_class = genomics_util.GetGenomicsMessages().SearchCallSetsRequest
    request = req_class(
        name=args.name,
        variantSetIds=args.variant_set_ids)
    return list_pager.YieldFromList(
        apitools_client.callsets,
        request,
        method='Search',
        limit=args.limit,
        batch_size_attribute='pageSize',
        batch_size=args.limit,  # Use limit if any, else server default.
        field='callSets')
