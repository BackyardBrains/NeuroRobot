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

"""A command that generates all DevSite and manpage documents."""

import sys

from googlecloudsdk.calliope import base
from googlecloudsdk.core.document_renderers import render_document
from googlecloudsdk.core.util import files


class GenerateHelpDocs(base.Command):
  """Uses gcloud's markdown renderer to render the given markdown file."""

  @staticmethod
  def Args(parser):
    parser.add_argument(
        'md_file',
        help=('The path to a file containing markdown to render, or `-` to '
              'read from stdin.'))
    parser.add_argument(
        '--style',
        default='text',
        choices=sorted(render_document.STYLES.keys()),
        help='The renderer output format.')

  def Run(self, args):
    with files.Open(args.md_file, 'r') as f:
      render_document.RenderDocument(args.style, f, sys.stdout)
