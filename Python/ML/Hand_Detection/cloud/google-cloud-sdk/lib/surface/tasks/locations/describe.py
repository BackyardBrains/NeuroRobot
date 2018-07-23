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
"""`gcloud tasks locations describe` command."""

from googlecloudsdk.api_lib.tasks import locations
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.tasks import parsers


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class Describe(base.DescribeCommand):
  """Show details about a location."""

  @staticmethod
  def Args(parser):
    base.Argument(
        'location', help='The Cloud location to describe.').AddToParser(parser)

  def Run(self, args):
    locations_client = locations.Locations()
    location_ref = parsers.ParseLocation(args.location)
    return locations_client.Get(location_ref)
