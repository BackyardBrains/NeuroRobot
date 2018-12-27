# Copyright 2017 Google Inc. All Rights Reserved.
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
"""The Create command for Binary Authorization attestations."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.container import binauthz_util as binauthz_api_util
from googlecloudsdk.api_lib.container.binauthz import authorities
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.container.binauthz import binauthz_util as binauthz_command_util
from googlecloudsdk.command_lib.container.binauthz import flags as binauthz_flags
from googlecloudsdk.core import properties
from googlecloudsdk.core import resources
from googlecloudsdk.core.console import console_io


class Create(base.CreateCommand):
  r"""Create a Binary Authorization attestation.

  This command creates a Binary Authorization attestation for your project. The
  attestation is created for the specified artifact (e.g. a grc.io container
  URL) and stored under the specified attestation authority (i.e. the Container
  Analysis Note).

  ## EXAMPLES

  To create an attestation as the attestation authority represented by an
  ATTESTATION_AUTHORITY Note with resource path
  "projects/exmple-prj/notes/note-id", run:

      $ {command} \
          --artifact-url='gcr.io/example-project/example-image@sha256:abcd' \
          --attestation-authority-note=projects/exmple-prj/notes/note-id \
          --signature-file=signed_artifact_attestation.pgp.sig \
          --pgp-key-fingerprint=AAAA0000000000000000FFFFFFFFFFFFFFFFFFFF
  """

  @staticmethod
  def Args(parser):
    binauthz_flags.AddCreateAttestationFlags(parser)

  def Run(self, args):
    project_ref = resources.REGISTRY.Parse(
        properties.VALUES.core.project.Get(required=True),
        collection='cloudresourcemanager.projects',
    )
    normalized_artifact_url = binauthz_command_util.NormalizeArtifactUrl(
        args.artifact_url)
    signature = console_io.ReadFromFileOrStdin(
        args.signature_file, binary=False)

    note_ref = args.CONCEPTS.attestation_authority_note.Parse()
    if note_ref is None:
      authority_ref = args.CONCEPTS.attestation_authority.Parse()
      authority = authorities.Client().Get(authority_ref)
      # TODO(b/79709480): Add other types of authorities if/when supported.
      note_ref = resources.REGISTRY.ParseResourceId(
          'containeranalysis.projects.notes',
          authority.userOwnedDrydockNote.noteReference, {})

    client = binauthz_api_util.ContainerAnalysisClient()
    return client.CreateAttestationOccurrence(
        project_ref=project_ref,
        note_ref=note_ref,
        artifact_url=normalized_artifact_url,
        pgp_key_fingerprint=args.pgp_key_fingerprint,
        signature=signature,
    )
