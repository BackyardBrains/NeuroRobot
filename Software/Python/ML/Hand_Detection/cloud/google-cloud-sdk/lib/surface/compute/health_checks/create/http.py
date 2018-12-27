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
"""Command for creating HTTP health checks."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import health_checks_utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import completers
from googlecloudsdk.command_lib.compute.health_checks import flags


def _Run(args, holder, supports_response=False,
         supports_port_specification=False):
  """Issues the request necessary for adding the health check."""
  client = holder.client
  messages = client.messages

  health_check_ref = flags.HealthCheckArgument('HTTP').ResolveAsResource(
      args, holder.resources)
  proxy_header = messages.HTTPHealthCheck.ProxyHeaderValueValuesEnum(
      args.proxy_header)
  http_health_check = messages.HTTPHealthCheck(
      host=args.host,
      port=args.port,
      portName=args.port_name,
      requestPath=args.request_path,
      proxyHeader=proxy_header)

  if supports_response:
    http_health_check.response = args.response
  if supports_port_specification:
    health_checks_utils.ValidateAndAddPortSpecificationToHealthCheck(
        args, http_health_check)

  request = messages.ComputeHealthChecksInsertRequest(
      healthCheck=messages.HealthCheck(
          name=health_check_ref.Name(),
          description=args.description,
          type=messages.HealthCheck.TypeValueValuesEnum.HTTP,
          httpHealthCheck=http_health_check,
          checkIntervalSec=args.check_interval,
          timeoutSec=args.timeout,
          healthyThreshold=args.healthy_threshold,
          unhealthyThreshold=args.unhealthy_threshold),
      project=health_check_ref.project)
  return client.MakeRequests(
      [(client.apitools_client.healthChecks, 'Insert', request)])


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Create(base.CreateCommand):
  """Create a HTTP health check to monitor load balanced instances."""

  @classmethod
  def Args(cls, parser):
    parser.display_info.AddFormat(flags.DEFAULT_LIST_FORMAT)
    flags.HealthCheckArgument('HTTP').AddArgument(parser,
                                                  operation_type='create')
    health_checks_utils.AddHttpRelatedCreationArgs(parser)
    health_checks_utils.AddProtocolAgnosticCreationArgs(parser, 'HTTP')
    parser.display_info.AddCacheUpdater(completers.HealthChecksCompleter)

  def Run(self, args):
    """Issues the request necessary for adding the health check."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    return _Run(args, holder)


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class CreateBeta(Create):
  """Create a HTTP health check to monitor load balanced instances."""

  @staticmethod
  def Args(parser):
    Create.Args(parser)
    health_checks_utils.AddHttpRelatedResponseArg(parser)
    parser.display_info.AddCacheUpdater(completers.HealthChecksCompleter)

  def Run(self, args):
    """Issues the request necessary for adding the health check."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    return _Run(args, holder, supports_response=True)


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class CreateAlpha(CreateBeta):
  """Create a HTTP health check to monitor load balanced instances."""

  @staticmethod
  def Args(parser):
    CreateBeta.Args(parser)
    health_checks_utils.AddPortSpecificationFlag(parser)
    parser.display_info.AddCacheUpdater(completers.HealthChecksCompleter)

  def Run(self, args):
    """Issues the request necessary for adding the health check."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    return _Run(
        args, holder, supports_response=True, supports_port_specification=True)


Create.detailed_help = {
    'brief': ('Create a HTTP health check to monitor load balanced instances'),
    'DESCRIPTION': """\
        *{command}* is used to create a HTTP health check. HTTP health checks
        monitor instances in a load balancer controlled by a target pool. All
        arguments to the command are optional except for the name of the health
        check. For more information on load balancing, see
        [](https://cloud.google.com/compute/docs/load-balancing-and-autoscaling/)
        """,
}
