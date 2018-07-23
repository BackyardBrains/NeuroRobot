# Copyright 2018 Google Inc. All Rights Reserved.
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
"""Category manager assets search."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.category_manager import assets
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.category_manager import flags
from googlecloudsdk.command_lib.util.concepts import concept_parsers

_MAX_PAGE_SIZE = 1000
PAGE_SIZE_ERR_FORMAT = ('--page-size: Value must be less than '
                        'or equal to {}; received: {}')


def GetMaxPageSize():
  return _MAX_PAGE_SIZE


class Search(base.ListCommand):
  """Search for annotatable assets.

  Search for annotatable assets. The default search behaviour displays all
  assets readable by the user.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    flags.AddQueryFilterFlag(parser)
    concept_parsers.ConceptParser(
        [flags.CreateAnnotationResourceArg(required=False,
                                           plural=True)]).AddToParser(parser)
    flags.AddMatchChildAnnotationsFlag(parser)
    flags.AddShowOnlyAnnotatableFlag(parser)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
      command invocation.

    Returns:
      Assets which matched the specified criteria provided on the CLI.

    Raises:
      ValueError: An error raised when the page size is invalid.
    """
    page_size = args.page_size
    if page_size is not None and page_size > _MAX_PAGE_SIZE:
      err_msg = PAGE_SIZE_ERR_FORMAT.format(_MAX_PAGE_SIZE, page_size)
      raise ValueError(err_msg)

    limit = args.limit
    query_filter = args.query
    show_only_annotatable = args.show_only_annotatable
    match_child_annotations = args.match_child_annotations
    annotation_resources = args.CONCEPTS.annotations.Parse()
    annotations = [
        annotation.RelativeName() for annotation in annotation_resources
    ]

    return assets.SearchAssets(
        annotations=annotations,
        show_only_annotatable=show_only_annotatable,
        match_child_annotations=match_child_annotations,
        query_filter=query_filter,
        page_size=page_size,
        limit=limit)
