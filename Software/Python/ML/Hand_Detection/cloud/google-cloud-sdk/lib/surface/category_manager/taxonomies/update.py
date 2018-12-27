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
"""Category manager taxonomies update."""

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals
from googlecloudsdk.api_lib.category_manager import taxonomies
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.category_manager import flags
from googlecloudsdk.command_lib.util.concepts import concept_parsers


class Update(base.Command):
  """Update the description of a taxonomy."""

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    concept_parsers.ConceptParser(
        [flags.CreateTaxonomyResourceArg(positional=True)]
    ).AddToParser(parser)
    update_group = parser.add_group(required=True)
    flags.AddDescriptionFlag(update_group, 'taxonomy', required=False)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
      command invocation.

    Returns:
      Status of command execution.
    """
    taxonomy_ref = args.CONCEPTS.taxonomy.Parse()
    return taxonomies.UpdateTaxonomy(taxonomy_ref, args.description)
