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
"""`gcloud tasks locations list` command."""

from googlecloudsdk.api_lib.tasks import locations
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.tasks import list_formats
from googlecloudsdk.command_lib.tasks import parsers


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class List(base.ListCommand):
  """Lists the locations where Cloud Tasks is available."""

  @staticmethod
  def Args(parser):
    list_formats.AddListLocationsFormats(parser)

  def Run(self, args):
    locations_client = locations.Locations()
    project_ref = parsers.ParseProject()
    return locations_client.List(project_ref, args.limit, args.page_size)
