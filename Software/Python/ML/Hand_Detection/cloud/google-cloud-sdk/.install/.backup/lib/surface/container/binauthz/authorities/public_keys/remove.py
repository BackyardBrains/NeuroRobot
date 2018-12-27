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

"""Remove Attestation Authority public key command."""

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals

from googlecloudsdk.api_lib.container.binauthz import authorities
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.container.binauthz import flags


class Remove(base.Command):
  """Remove a public key from an Attestation Authority."""

  @staticmethod
  def Args(parser):
    flags.AddConcepts(
        parser,
        flags.GetAuthorityPresentationSpec(
            required=True,
            positional=False,
            group_help=(
                'The authority from which the public key should be removed.'),
        ),
    )
    parser.add_argument('public_key_fingerprint',
                        help='The fingerprint of the public key to remove.')

  def Run(self, args):
    authorities_client = authorities.Client()

    authority_ref = args.CONCEPTS.authority.Parse()

    authorities_client.RemoveKey(
        authority_ref, fingerprint_to_remove=args.public_key_fingerprint)
