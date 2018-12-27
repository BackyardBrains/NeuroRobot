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

"""Create Attestation Authority command."""

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals

import textwrap

from googlecloudsdk.api_lib.container.binauthz import authorities
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.container.binauthz import flags


class Create(base.CreateCommand):
  """Create an Attestation Authority."""

  @staticmethod
  def Args(parser):
    flags.AddConcepts(
        parser,
        flags.GetAuthorityPresentationSpec(
            positional=True,
            group_help='The authority to be created.',
        ),
        flags.GetAuthorityNotePresentationSpec(
            base_name='authority-note',
            required=True,
            positional=False,
            group_help=textwrap.dedent("""\
                The Container Analysis ATTESTATION_AUTHORITY Note to which the
                created attestation authority will be bound.

                For the attestation authority to be able to access and use the Note,
                the Note must exist and the active gcloud account (core/account)
                must have the `containeranalysis.occurrences.viewer` permission
                for the Note. This can be achieved by granting the
                `containeranalysis.notes.viewer` role to the active account for
                the Note resource in question.

                """),
        ),
    )
    # TODO(b/74193183): Add a comment option.

  def Run(self, args):
    authority_ref = args.CONCEPTS.authority.Parse()
    note_ref = args.CONCEPTS.authority_note.Parse()

    # TODO(b/74193183): Add a comment option.
    return authorities.Client().Create(authority_ref, note_ref)
