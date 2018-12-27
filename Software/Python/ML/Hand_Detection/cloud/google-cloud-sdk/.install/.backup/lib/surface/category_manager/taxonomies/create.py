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
"""Category manager taxonomies create."""

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals
from googlecloudsdk.api_lib.category_manager import taxonomies
from googlecloudsdk.api_lib.category_manager import utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.category_manager import flags


class Create(base.Command):
  """Create a taxonomy in a project.

  Create a taxonomy in a project. By default the taxonomy is created for the
  current project, but this can be overridden with the --project flag.
  """

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    flags.AddDisplayNameFlag(parser, 'taxonomy')
    flags.AddDescriptionFlag(parser, 'taxonomy', required=False)

  def Run(self, args):
    """See base class.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
      command invocation.

    Returns:
      Status of command execution.
    """
    project_resource = utils.GetProjectResource()
    return taxonomies.CreateTaxonomy(project_resource, args.display_name,
                                     args.description)
