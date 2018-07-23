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

"""Command to list all devices in a project and location."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.cloudiot import devices
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.iot import resource_args
from googlecloudsdk.command_lib.iot import util


@base.ReleaseTracks(base.ReleaseTrack.BETA, base.ReleaseTrack.GA)
class List(base.ListCommand):
  """List devices."""

  @staticmethod
  def Args(parser):
    parser.display_info.AddFormat('table(id, numId, blocked)')
    parser.display_info.AddUriFunc(util.DevicesUriFunc)

    resource_args.AddRegistryResourceArg(parser, 'in which to show devices',
                                         positional=False)

    base.Argument(
        '--device-ids',
        metavar='[ID,...]',
        type=arg_parsers.ArgList(),
        help='If given, show only devices with one of the provided IDs.'
        ).AddToParser(parser)
    base.Argument(
        '--device-num-ids',
        metavar='[NUM_ID,...]',
        type=arg_parsers.ArgList(element_type=int),
        help=('If given, show only devices with one of the provided numerical '
              'IDs.')).AddToParser(parser)

  def Run(self, args):
    """Run the list command."""
    client = devices.DevicesClient()

    registry_ref = args.CONCEPTS.registry.Parse()

    return client.List(
        registry_ref,
        device_ids=args.device_ids,
        device_num_ids=args.device_num_ids,
        field_mask=[
            'blocked',
            'name'],
        limit=args.limit, page_size=args.page_size)
