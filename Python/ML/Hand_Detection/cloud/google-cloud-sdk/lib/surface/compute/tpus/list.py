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
"""cloud tpu list command."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.tpus import util as cli_util


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class List(base.ListCommand):
  """List Cloud TPUs."""

  @staticmethod
  def Args(parser):
    parser.display_info.AddFormat(cli_util.LIST_FORMAT)
    compute_flags.AddZoneFlag(
        parser,
        resource_type='tpu',
        operation_type='list',
        explanation=(
            'List TPUs from this zone. '
            'If not specified, will list TPUs in `default` compute/zone.'))
    parser.display_info.AddCacheUpdater(None)

  def Run(self, args):
    return cli_util.List(
        page_size=args.page_size,
        limit=args.limit,
        zone=args.zone)
