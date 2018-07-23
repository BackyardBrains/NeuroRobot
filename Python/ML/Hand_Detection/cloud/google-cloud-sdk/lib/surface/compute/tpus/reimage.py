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
"""cloud tpu reimage command."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.tpus import util as cli_util
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class Reimage(base.UpdateCommand):
  """Reimages the OS on a Cloud TPU."""

  @staticmethod
  def Args(parser):
    cli_util.AddReimageResourcesToParser(parser)

  def Run(self, args):
    tpu_ref = args.CONCEPTS.tpu_id.Parse()
    result = cli_util.Reimage(tpu_ref, args.version, args.zone)
    log.err.Print('Reimaged tpu [{0}].'.format(tpu_ref.Name()))
    return result
