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

"""rolling-updates list-instance-updates command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions
from apitools.base.py import list_pager

from googlecloudsdk.api_lib.compute import rolling_updates_util as updater_util
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import properties
from googlecloudsdk.core import resources


class ListInstanceUpdates(base.ListCommand):
  """Lists all instance updates for a given update."""

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command.

    Args:
      parser: An argparse parser that you can use to add arguments that go
          on the command line after this command. Positional arguments are
          allowed.
    """
    parser.add_argument('update', help='Update id.')
    parser.display_info.AddFormat(
        'table(instance.basename():label=INSTANCE_NAME, status)')

  def Run(self, args):
    """Run 'rolling-updates list-instance-updates'.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Returns:
      List of all the instance updates.

    Raises:
      HttpException: An http error response was received while executing api
          request.
      ToolException: An error other than http error occured while executing
          the command.
    """
    client = updater_util.GetApiClientInstance()
    messages = updater_util.GetApiMessages()

    ref = resources.REGISTRY.Parse(
        args.update,
        params={
            'project': properties.VALUES.core.project.GetOrFail,
            'zone': properties.VALUES.compute.zone.GetOrFail,
        },
        collection='replicapoolupdater.rollingUpdates')
    request = (
        messages.ReplicapoolupdaterRollingUpdatesListInstanceUpdatesRequest(
            project=ref.project,
            zone=ref.zone,
            rollingUpdate=ref.rollingUpdate))

    try:
      return list_pager.YieldFromList(
          client.rollingUpdates, request, method='ListInstanceUpdates')
    except apitools_exceptions.HttpError as error:
      raise exceptions.HttpException(error)
