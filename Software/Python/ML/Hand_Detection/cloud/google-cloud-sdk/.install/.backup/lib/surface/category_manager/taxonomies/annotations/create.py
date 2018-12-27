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
"""Category manager annotations create."""

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals
from googlecloudsdk.api_lib.category_manager import annotations
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.category_manager import flags
from googlecloudsdk.command_lib.util.concepts import concept_parsers


# TODO(b/74408080): Replace this file with YAML once the create bug is fixed.
class Create(base.Command):
  """Create an annotation in the specified taxonomy.

  Create an annotation in the specified taxonomy. By default the annotation is
  created as a root annotation, but an annotation can also be created as a child
  of another annotation by specifying the --parent_annotation flag.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    concept_parsers.ConceptParser(
        [flags.CreateTaxonomyResourceArg()]).AddToParser(parser)
    flags.AddDisplayNameFlag(parser, 'annotation')
    flags.AddDescriptionFlag(parser, 'annotation', required=False)
    flags.AddParentAnnotationFlag(parser)

  def Run(self, args):
    """See base class.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
      command invocation.

    Returns:
      Status of command execution.
    """
    taxonomy_resource = args.CONCEPTS.taxonomy.Parse()
    return annotations.CreateAnnotation(taxonomy_resource, args.display_name,
                                        args.description,
                                        args.parent_annotation)
