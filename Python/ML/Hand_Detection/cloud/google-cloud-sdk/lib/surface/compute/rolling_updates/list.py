# Copyright 2014 Google Inc. All Rights Reserved.
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

"""rolling-updates list command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions
from apitools.base.py import list_pager

from googlecloudsdk.api_lib.compute import rolling_updates_util as updater_util
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import properties


class List(base.ListCommand):
  """Lists all updates for a given group."""

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command.

    Args:
      parser: An argparse parser that you can use to add arguments that go
          on the command line after this command. Positional arguments are
          allowed.
    """
    parser.add_argument('--group',
                        help='Managed instance group name.')
    parser.display_info.AddFormat("""
          table(
            id,
            instanceGroupManager.basename():label=GROUP_NAME,
            instanceTemplate.basename():label=TEMPLATE_NAME,
            status,
            statusMessage
          )
    """)

  def Run(self, args):
    """Run 'rolling-updates list'.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Yields:
      List of all the updates.

    Raises:
      HttpException: An http error response was received while executing api
          request.
      ToolException: An error other than http error occured while executing
          the command.
    """
    client = updater_util.GetApiClientInstance()
    messages = updater_util.GetApiMessages()

    request = messages.ReplicapoolupdaterRollingUpdatesListRequest(
        project=properties.VALUES.core.project.Get(required=True),
        zone=properties.VALUES.compute.zone.Get(required=True))
    if args.group:
      request.filter = 'instanceGroup eq %s' % args.group

    try:
      for item in list_pager.YieldFromList(
          client.rollingUpdates, request, limit=args.limit):
        # TODO(b/36050943): Consider getting rid of instance group manager in
        # api.
        if item.instanceGroup:
          item.instanceGroupManager = item.instanceGroup
        yield item
    except apitools_exceptions.HttpError as error:
      raise exceptions.HttpException(error)
