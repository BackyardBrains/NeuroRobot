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

"""Implementation of gcloud genomics reads list.
"""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import list_pager

from googlecloudsdk.api_lib.genomics import genomics_util
from googlecloudsdk.calliope import base


class List(base.ListCommand):
  """Lists reads within a given read group set.

  Prints a table with summary information on reads in the read group set.
  Results may be restricted to reads which are aligned to a given reference
  (--reference-name) or may be further filtered to reads that have alignments
  overlapping a given range (--reference-name, --start, --end).
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    parser.add_argument('read_group_set_id',
                        type=str,
                        help=('Restrict the list to reads in this read '
                              'group set.'))
    parser.add_argument('--reference-name',
                        type=str,
                        help=('Only return reads which are aligned to this '
                              'reference. Pass * to list unmapped reads '
                              'only.'))
    parser.add_argument('--start',
                        type=int,
                        help=('The beginning of the window (0-based '
                              'inclusive) for which overlapping reads '
                              'should be returned. If unspecified, defaults '
                              'to 0.'))
    parser.add_argument('--end',
                        type=int,
                        help=('The end of the window (0-based exclusive) for '
                              'which overlapping reads should be returned. If '
                              'unspecified or 0, defaults to the length of '
                              'the reference.'))
    base.PAGE_SIZE_FLAG.SetDefault(parser, 512)
    parser.display_info.AddFormat("""
          table(
            alignment.position.referenceName,
            alignment.position.position,
            alignment.position.reverseStrand,
            fragmentName,
            alignedSequence:label=SEQUENCE
          )
        """)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace, All the arguments that were provided to this
        command invocation.

    Returns:
      A list of reads that meet the search criteria.
    """
    apitools_client = genomics_util.GetGenomicsClient()
    messages = genomics_util.GetGenomicsMessages()
    fields = genomics_util.GetQueryFields(self.GetReferencedKeyNames(args),
                                          'alignments')
    if fields:
      global_params = messages.StandardQueryParameters(fields=fields)
    else:
      global_params = None

    return list_pager.YieldFromList(
        apitools_client.reads,
        messages.SearchReadsRequest(
            readGroupSetIds=[args.read_group_set_id],
            referenceName=args.reference_name,
            start=args.start,
            end=args.end),
        global_params=global_params,
        limit=args.limit,
        method='Search',
        batch_size_attribute='pageSize',
        batch_size=args.page_size,
        field='alignments')
