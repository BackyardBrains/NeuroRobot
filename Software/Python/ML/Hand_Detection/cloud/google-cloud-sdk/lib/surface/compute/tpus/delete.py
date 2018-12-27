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
"""cloud tpu delete command."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.tpus import flags
from googlecloudsdk.command_lib.compute.tpus import util as cli_util
from googlecloudsdk.core import log
from googlecloudsdk.core.console import console_io


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class Delete(base.DeleteCommand):
  """Deletes a Cloud TPU."""

  @staticmethod
  def Args(parser):
    flags.GetTPUNameArg().AddToParser(parser)
    compute_flags.AddZoneFlag(
        parser,
        resource_type='tpu',
        operation_type='delete',
        explanation=(
            'Zone in which TPU lives. '
            'If not specified, will use `default` compute/zone.'))
    parser.display_info.AddCacheUpdater(None)

  def Run(self, args):
    tpu = args.tpu_id
    console_io.PromptContinue(
        'You are about to delete tpu [{}]'.format(tpu),
        default=True,
        cancel_on_no=True,
        cancel_string='Aborted by user.')

    result = cli_util.Delete(tpu, args.zone)
    log.DeletedResource(args.tpu_id, kind='tpu')
    return result
