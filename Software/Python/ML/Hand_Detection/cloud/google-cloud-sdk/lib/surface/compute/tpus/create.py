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
"""cloud tpu create command."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.tpus import flags
from googlecloudsdk.command_lib.compute.tpus import util as cli_util
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class Create(base.CreateCommand):
  r"""Create a new Cloud TPU.


  ## EXAMPLES

  The following command creates a TPU with ID `my-tpu` and CIDR range
  `10.240.0.0/29` in the default user project, network and compute/region
  (with other defaults supplied by API):

    $ {command}  my-tpu --range 10.240.0.0/29


  The following command creates a TPU with ID `my-tpu` with explicit values
  for all required and optional parameters:

    $ {command} my-tpu \
        --zone us-central1-a \
        --range '10.240.0.0/29' \
        --accelerator-type 'v2-8' \
        --network my-tf-network \
        --description 'My TF Node' \
        --version '1.1'
  """

  @staticmethod
  def Args(parser):
    flags.GetTPUNameArg().AddToParser(parser)
    flags.GetAcceleratorTypeFlag().AddToParser(parser)
    flags.GetDescriptionFlag().AddToParser(parser)
    flags.GetNetworkFlag().AddToParser(parser)
    flags.GetVersionFlag().AddToParser(parser)
    flags.GetRangeFlag().AddToParser(parser)
    compute_flags.AddZoneFlag(
        parser,
        resource_type='tpu',
        operation_type='create',
        explanation=(
            'Zone in which TPU lives. '
            'If not specified, will use default compute/zone.'))
    parser.display_info.AddCacheUpdater(None)

  def Run(self, args):
    tpu = args.tpu_id
    operation_result = cli_util.Create(
        tpu,
        args.range,
        description=args.description,
        network=args.network,
        accelerator_type=args.accelerator_type,
        version=args.version,
        zone=args.zone)

    log.CreatedResource(tpu, 'tpu')
    return operation_result.response
