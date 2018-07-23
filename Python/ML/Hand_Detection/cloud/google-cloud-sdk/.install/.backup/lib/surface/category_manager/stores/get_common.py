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
"""Category manager stores get-common command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.category_manager import store
from googlecloudsdk.calliope import base


class GetCommon(base.Command):
  """Get common taxonomy store of Google-defined taxonomies."""

  @staticmethod
  def Args(parser):
    """Registers flags for this command."""
    pass

  def Run(self, args):
    """See base class.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
      command invocation.

    Returns:
      Status of command execution.
    """
    return store.GetCommonStore()
