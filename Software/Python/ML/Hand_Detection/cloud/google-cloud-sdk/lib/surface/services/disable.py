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

"""services disable command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.services import services_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.services import arg_parsers
from googlecloudsdk.command_lib.services import common_flags
from googlecloudsdk.core import properties


class Disable(base.SilentCommand):
  # pylint: disable=line-too-long
  """Disable a service for consumption for a project.

     This command disables one or more previously-enabled services for consumption.

     To see a list of the enabled services for a project, run:

       $ {parent_command} list

     More information on listing services can be found at:
     https://cloud.google.com/service-management/list-services and on
     disabling a service at:
     https://cloud.google.com/service-management/enable-disable#disabling_services

     ## EXAMPLES
     To disable a service called `my-consumed-service` for the active
     project, run:

       $ {command} my-consumed-service

     To run the same command asynchronously (non-blocking), run:

       $ {command} my-consumed-service --async
  """
  # pylint: enable=line-too-long

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command.

    Args:
      parser: An argparse parser that you can use to add arguments that go
          on the command line after this command. Positional arguments are
          allowed.
    """
    common_flags.consumer_service_flag(suffix='to disable').AddToParser(parser)
    base.ASYNC_FLAG.AddToParser(parser)

  def Run(self, args):
    """Run 'service-management disable'.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Returns:
      Nothing.
    """
    messages = services_util.GetMessagesModule()
    client = services_util.GetClientInstance()

    project = properties.VALUES.core.project.Get(required=True)
    for service_name in args.service:
      service_name = arg_parsers.GetServiceNameFromArg(service_name)
      request = messages.ServicemanagementServicesDisableRequest(
          serviceName=service_name,
          disableServiceRequest=messages.DisableServiceRequest(
              consumerId='project:' + project))
      operation = client.services.Disable(request)
      services_util.ProcessOperationResult(operation, args.async)
