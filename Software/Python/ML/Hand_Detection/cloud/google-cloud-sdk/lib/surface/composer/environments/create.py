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
"""Command to create an environment."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.composer import environments_util as environments_api_util
from googlecloudsdk.api_lib.composer import operations_util as operations_api_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.composer import flags
from googlecloudsdk.command_lib.composer import parsers
from googlecloudsdk.command_lib.composer import resource_args
from googlecloudsdk.command_lib.composer import util as command_util
from googlecloudsdk.command_lib.util.args import labels_util
from googlecloudsdk.core import log


class Create(base.Command):
  """Creates and initializes a Cloud Composer environment.

  If run asynchronously with `--async`, exits after printing an operation
  that can be used to poll the status of the creation operation via:

    {top_command} composer operations describe
  """

  @staticmethod
  def Args(parser):
    resource_args.AddEnvironmentResourceArg(parser, 'to create')
    base.ASYNC_FLAG.AddToParser(parser)
    parser.add_argument(
        '--node-count',
        type=int,
        help='The number of nodes to create to run the environment.')
    parser.add_argument(
        '--zone',
        help='The Compute Engine zone in which the environment will '
        'be created. For example `--zone=us-central1-a`.')
    parser.add_argument(
        '--machine-type',
        help='The Compute Engine machine type '
        '(https://cloud.google.com/compute/docs/machine-types) to use for '
        'nodes. For example `--machine-type=n1-standard-1`.')

    parser.add_argument(
        '--disk-size',
        default='100GB',
        type=arg_parsers.BinarySize(
            lower_bound='20GB',
            upper_bound='64TB',
            suggested_binary_size_scales=['GB', 'TB']),
        help='The disk size for each VM node in the environment. The minimum '
        'size is 20GB, and the maximum is 64TB. Specified value must be an '
        'integer multiple of gigabytes. Cannot be updated after the '
        'environment has been created. If units are not provided, defaults to '
        'GB.')
    networking_group = parser.add_group(help='Virtual Private Cloud networking')
    networking_group.add_argument(
        '--network',
        required=True,
        help='The Compute Engine Network to which the environment will '
        'be connected. If a \'Custom Subnet Network\' is provided, '
        '`--subnetwork` must be specified as well.')
    networking_group.add_argument(
        '--subnetwork',
        help='The Compute Engine subnetwork '
        '(https://cloud.google.com/compute/docs/subnetworks) to which the '
        'environment will be connected.')
    labels_util.AddCreateLabelsFlags(parser)
    flags.CREATE_ENV_VARS_FLAG.AddToParser(parser)
    # Default is provided by API server.
    parser.add_argument(
        '--service-account',
        help='The Google Cloud Platform service account to be used by the node '
        'VMs. If a service account is not specified, the "default" Compute '
        'Engine service account for the project is used. Cannot be updated.')
    # Default is provided by API server.
    parser.add_argument(
        '--oauth-scopes',
        help='The set of Google API scopes to be made available on all of the '
        'node VMs. Defaults to '
        '[\'https://www.googleapis.com/auth/cloud-platform\']. Cannot be '
        'updated.',
        type=arg_parsers.ArgList(),
        metavar='SCOPE',
        action=arg_parsers.UpdateAction)
    parser.add_argument(
        '--tags',
        help='The set of instance tags applied to all node VMs. Tags are used '
        'to identify valid sources or targets for network firewalls. Each tag '
        'within the list must comply with RFC 1035. Cannot be updated.',
        type=arg_parsers.ArgList(),
        metavar='TAG',
        action=arg_parsers.UpdateAction)

    # API server will validate key/value pairs.
    parser.add_argument(
        '--airflow-configs',
        help="""\
A list of Airflow software configuration override KEY=VALUE pairs to set. For
information on how to structure KEYs and VALUEs, run
`$ {top_command} help composer environments update`.""",
        type=arg_parsers.ArgDict(),
        metavar='KEY=VALUE',
        action=arg_parsers.UpdateAction)

  def Run(self, args):
    flags.ValidateDiskSize('--disk-size', args.disk_size)
    env_ref = args.CONCEPTS.environment.Parse()
    env_name = env_ref.Name()
    if not command_util.IsValidEnvironmentName(env_name):
      raise command_util.InvalidUserInputError(
          'Invalid environment name: [{}]. Must match pattern: {}'.format(
              env_name, command_util.ENVIRONMENT_NAME_PATTERN.pattern))

    zone_ref = parsers.ParseZone(args.zone) if args.zone else None
    zone = zone_ref.RelativeName() if zone_ref else None
    machine_type = None
    network = None
    subnetwork = None
    if args.machine_type:
      machine_type = parsers.ParseMachineType(
          args.machine_type, fallback_zone=zone_ref.Name()
          if zone_ref else None).RelativeName()
    if args.network:
      network = parsers.ParseNetwork(args.network).RelativeName()
    if args.subnetwork:
      subnetwork = parsers.ParseSubnetwork(
          args.subnetwork,
          fallback_region=env_ref.Parent().Name()).RelativeName()
    operation = environments_api_util.Create(
        env_ref,
        args.node_count,
        labels=args.labels,
        location=zone,
        machine_type=machine_type,
        network=network,
        subnetwork=subnetwork,
        env_variables=args.env_variables,
        airflow_config_overrides=args.airflow_configs,
        service_account=args.service_account,
        oauth_scopes=args.oauth_scopes,
        tags=args.tags,
        disk_size_gb=args.disk_size >> 30)
    details = 'with operation [{0}]'.format(operation.name)
    if args.async:
      log.CreatedResource(
          env_ref.RelativeName(),
          kind='environment',
          is_async=True,
          details=details)
      return operation
    else:
      try:
        operations_api_util.WaitForOperation(
            operation, 'Waiting for [{}] to be created with [{}]'.format(
                env_ref.RelativeName(), operation.name))
      except command_util.OperationError as e:
        raise command_util.EnvironmentCreateError(
            'Error creating [{}]: {}'.format(env_ref.RelativeName(), str(e)))
