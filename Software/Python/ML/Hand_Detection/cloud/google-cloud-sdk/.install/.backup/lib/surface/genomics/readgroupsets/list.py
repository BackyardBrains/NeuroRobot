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

"""readgroupsets list command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import list_pager

from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base


class List(base.ListCommand):
  """List genomics read group sets in a dataset.

  Prints a table with summary information on read group sets in the dataset.
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
        'dataset_ids',
        nargs='+',
        help="""Restrict the query to read group sets within the given datasets.
             At least one ID must be provided.""")

    parser.add_argument(
        '--name',
        help="""Only return read group sets for which a substring of the
             name matches this string.""")
    base.PAGE_SIZE_FLAG.SetDefault(parser, 128)

    parser.display_info.AddFormat("""
          table(
            id,
            name,
            referenceSetId
          )
        """)

  def Run(self, args):
    """Run 'readgroupsets list'.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Returns:
      The list of read group sets matching the given dataset ids.

    Raises:
      HttpException: An http error response was received while executing api
          request.
    """
    apitools_client = genomics_util.GetGenomicsClient()
    messages = genomics_util.GetGenomicsMessages()
    req_class = messages.SearchReadGroupSetsRequest
    fields = genomics_util.GetQueryFields(
        self.GetReferencedKeyNames(args), 'readGroupSets')
    if fields:
      global_params = messages.StandardQueryParameters(fields=fields)
    else:
      global_params = None

    page_size = args.page_size
    if args.limit and args.limit < page_size:
      page_size = args.limit

    return list_pager.YieldFromList(apitools_client.readgroupsets,
                                    req_class(name=args.name,
                                              datasetIds=args.dataset_ids),
                                    method='Search',
                                    global_params=global_params,
                                    limit=args.limit,
                                    batch_size_attribute='pageSize',
                                    batch_size=page_size,
                                    field='readGroupSets')
