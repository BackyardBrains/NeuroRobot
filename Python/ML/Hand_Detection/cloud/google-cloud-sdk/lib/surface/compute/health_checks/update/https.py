# Copyright 2015 Google Inc. All Rights Reserved.
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
"""Command for updating health checks."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import health_checks_utils
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.command_lib.compute.health_checks import flags
from googlecloudsdk.core import exceptions as core_exceptions
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Update(base.UpdateCommand):
  """Update a HTTPS health check.

  *{command}* is used to update an existing HTTPS health check. Only
  arguments passed in will be updated on the health check. Other
  attributes will remain unaffected.
  """

  HEALTH_CHECK_ARG = None

  @classmethod
  def Args(cls, parser):
    cls.HEALTH_CHECK_ARG = flags.HealthCheckArgument('HTTPS')
    cls.HEALTH_CHECK_ARG.AddArgument(parser, operation_type='update')
    health_checks_utils.AddHttpRelatedUpdateArgs(parser)
    health_checks_utils.AddProtocolAgnosticUpdateArgs(parser, 'HTTPS')

  def GetGetRequest(self, client, health_check_ref):
    """Returns a request for fetching the existing health check."""
    return (client.apitools_client.healthChecks,
            'Get',
            client.messages.ComputeHealthChecksGetRequest(
                healthCheck=health_check_ref.Name(),
                project=health_check_ref.project))

  def GetSetRequest(self, client, health_check_ref, replacement):
    """Returns a request for updating the health check."""
    return (client.apitools_client.healthChecks,
            'Update',
            client.messages.ComputeHealthChecksUpdateRequest(
                healthCheck=health_check_ref.Name(),
                healthCheckResource=replacement,
                project=health_check_ref.project))

  def Modify(self, client, args, existing_check):
    """Returns a modified HealthCheck message."""
    # We do not support using 'update https' with a health check of a
    # different protocol.
    if (existing_check.type !=
        client.messages.HealthCheck.TypeValueValuesEnum.HTTPS):
      raise core_exceptions.Error(
          'update https subcommand applied to health check with protocol ' +
          existing_check.type.name)

    # Description, PortName, and Host are the only attributes that can be
    # cleared by passing in an empty string (but we don't want to set it to
    # an empty string).
    if args.description:
      description = args.description
    elif args.description is None:
      description = existing_check.description
    else:
      description = None

    if args.host:
      host = args.host
    elif args.host is None:
      host = existing_check.httpsHealthCheck.host
    else:
      host = None

    if args.port_name:
      port_name = args.port_name
    elif args.port_name is None:
      port_name = existing_check.httpsHealthCheck.portName
    else:
      port_name = None

    proxy_header = existing_check.httpsHealthCheck.proxyHeader
    if args.proxy_header is not None:
      proxy_header = (
          client.messages.HTTPSHealthCheck.ProxyHeaderValueValuesEnum(
              args.proxy_header))
    new_health_check = client.messages.HealthCheck(
        name=existing_check.name,
        description=description,
        type=client.messages.HealthCheck.TypeValueValuesEnum.HTTPS,
        httpsHealthCheck=client.messages.HTTPSHealthCheck(
            host=host,
            port=args.port or existing_check.httpsHealthCheck.port,
            portName=port_name,
            requestPath=(args.request_path or
                         existing_check.httpsHealthCheck.requestPath),
            proxyHeader=proxy_header),
        checkIntervalSec=(args.check_interval or
                          existing_check.checkIntervalSec),
        timeoutSec=args.timeout or existing_check.timeoutSec,
        healthyThreshold=(args.healthy_threshold or
                          existing_check.healthyThreshold),
        unhealthyThreshold=(args.unhealthy_threshold or
                            existing_check.unhealthyThreshold),
    )
    return new_health_check

  def ValidateArgs(self, args):
    health_checks_utils.CheckProtocolAgnosticArgs(args)

    args_unset = not (args.port
                      or args.request_path
                      or args.check_interval
                      or args.timeout
                      or args.healthy_threshold
                      or args.unhealthy_threshold
                      or args.proxy_header)
    if (args.description is None and args.host is None and
        args.port_name is None and args_unset):
      raise exceptions.ToolException('At least one property must be modified.')

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    self.ValidateArgs(args)
    health_check_ref = self.HEALTH_CHECK_ARG.ResolveAsResource(
        args, holder.resources)
    get_request = self.GetGetRequest(client, health_check_ref)

    objects = client.MakeRequests([get_request])

    new_object = self.Modify(client, args, objects[0])

    # If existing object is equal to the proposed object or if
    # Modify() returns None, then there is no work to be done, so we
    # print the resource and return.
    if objects[0] == new_object:
      log.status.Print(
          'No change requested; skipping update for [{0}].'.format(
              objects[0].name))
      return objects

    return client.MakeRequests(
        [self.GetSetRequest(client, health_check_ref, new_object)])


@base.ReleaseTracks(base.ReleaseTrack.BETA, base.ReleaseTrack.ALPHA)
class UpdateBeta(Update):
  """Update a HTTPS health check.

  *{command}* is used to update an existing HTTPS health check. Only
  arguments passed in will be updated on the health check. Other
  attributes will remain unaffected.
  """

  @staticmethod
  def Args(parser):
    Update.Args(parser)
    health_checks_utils.AddHttpRelatedResponseArg(parser)

  def Modify(self, client, args, existing_check):
    """Returns a modified HealthCheck message."""
    new_health_check = super(UpdateBeta, self).Modify(client, args,
                                                      existing_check)

    if args.response:
      response = args.response
    elif args.response is None:
      response = existing_check.httpsHealthCheck.response
    else:
      response = None

    new_health_check.httpsHealthCheck.response = response
    return new_health_check

  def ValidateArgs(self, args):
    health_checks_utils.CheckProtocolAgnosticArgs(args)

    args_unset = not (args.port
                      or args.request_path
                      or args.check_interval
                      or args.timeout
                      or args.healthy_threshold
                      or args.unhealthy_threshold
                      or args.proxy_header)
    if (args.description is None and args.host is None and args.response is None
        and args.port_name is None and args_unset):
      raise exceptions.ToolException('At least one property must be modified.')
