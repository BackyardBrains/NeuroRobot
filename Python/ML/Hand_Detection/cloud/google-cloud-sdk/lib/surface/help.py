# Copyright 2013 Google Inc. All Rights Reserved.
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

"""A calliope command that prints help for another calliope command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.calliope import base


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Help(base.Command):
  """Prints detailed help messages for the specified commands.

  This command prints a detailed help message for the commands specified
  after the ``help'' operand.
  """

  @staticmethod
  def Args(parser):
    parser.add_argument(
        'command',
        nargs='*',
        help="""\
        A sequence of group and command names with no flags.
        """)

  def Run(self, args):
    # --document=style=help to signal the metrics.Help() 'help' label in
    # actions.RenderDocumentAction().Action().
    self.ExecuteCommandDoNotUse(args.command + ['--document=style=help'])
    return None
