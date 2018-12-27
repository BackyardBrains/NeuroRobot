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

"""Update Attestation Authority command."""

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals

from googlecloudsdk.api_lib.container.binauthz import authorities
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.container.binauthz import flags


# TODO(b/74193183): Unhide when there are fields available to update.
@base.Hidden
class Update(base.UpdateCommand):
  """Update an existing Attestation Authority."""

  @staticmethod
  def Args(parser):
    # TODO(b/74193183): Add a comment option.
    flags.AddConcepts(
        parser,
        flags.GetAuthorityPresentationSpec(
            positional=True,
            group_help='The authority to update.'
        ),
    )

  def Run(self, args):
    authority_ref = args.CONCEPTS.authority.Parse()

    # TODO(b/74193183): Add a comment option.
    return authorities.Client().Update(authority_ref)
