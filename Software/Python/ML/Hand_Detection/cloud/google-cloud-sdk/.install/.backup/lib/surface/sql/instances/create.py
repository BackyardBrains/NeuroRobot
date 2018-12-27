# Copyright 2016 Google Inc. All Rights Reserved.
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
"""Creates a new Cloud SQL instance."""
from __future__ import absolute_import
from __future__ import division

from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions

from googlecloudsdk.api_lib.compute import utils as compute_utils
from googlecloudsdk.api_lib.sql import api_util as common_api_util
from googlecloudsdk.api_lib.sql import operations
from googlecloudsdk.api_lib.sql import validate
from googlecloudsdk.api_lib.storage import storage_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.command_lib.sql import flags
from googlecloudsdk.command_lib.sql import instances as command_util
from googlecloudsdk.command_lib.sql import validate as command_validate
from googlecloudsdk.command_lib.util.args import labels_util
from googlecloudsdk.core import log
from googlecloudsdk.core import properties
from googlecloudsdk.core.console import console_io
from googlecloudsdk.core.resource import resource_lex
from googlecloudsdk.core.resource import resource_property


def AddBaseArgs(parser):
  """Declare flag and positional arguments for this command parser."""
  # TODO(b/35705305): move common flags to command_lib.sql.flags
  base.ASYNC_FLAG.AddToParser(parser)
  parser.display_info.AddFormat(flags.INSTANCES_FORMAT_BETA)
  flags.AddActivationPolicy(parser)
  flags.AddAssignIp(parser, show_negated_in_help=False)
  flags.AddAuthorizedGAEApps(parser)
  flags.AddAuthorizedNetworks(parser)
  flags.AddAvailabilityType(parser)
  parser.add_argument(
      '--backup',
      required=False,
      action='store_true',
      default=True,
      help='Enables daily backup.')
  flags.AddBackupStartTime(parser)
  flags.AddCPU(parser)
  flags.AddDatabaseFlags(parser)
  parser.add_argument(
      '--database-version',
      required=False,
      default='MYSQL_5_6',
      choices=['MYSQL_5_5', 'MYSQL_5_6', 'MYSQL_5_7', 'POSTGRES_9_6'],
      help='The database engine type and version.')
  flags.AddEnableBinLog(parser, show_negated_in_help=False)
  parser.add_argument(
      '--failover-replica-name',
      required=False,
      help='Also create a failover replica with the specified name.')
  parser.add_argument(
      '--follow-gae-app',
      required=False,
      help=('First Generation instances only. The App Engine app this '
            'instance should follow. It must be in the same region as '
            'the instance.'))
  # TODO(b/73362466): Add `--zone` and deprecate `--gce-zone`.
  parser.add_argument(
      '--gce-zone',
      required=False,
      help=('The preferred Compute Engine zone (e.g. us-central1-a, '
            'us-central1-b, etc.).'))
  parser.add_argument(
      'instance',
      type=command_validate.InstanceNameRegexpValidator(),
      help='Cloud SQL instance ID.')
  flags.AddMaintenanceReleaseChannel(parser)
  flags.AddMaintenanceWindowDay(parser)
  flags.AddMaintenanceWindowHour(parser)
  parser.add_argument(
      '--master-instance-name',
      required=False,
      help=('Name of the instance which will act as master in the '
            'replication setup. The newly created instance will be a read '
            'replica of the specified master instance.'))
  flags.AddMemory(parser)
  parser.add_argument(
      '--pricing-plan',
      '-p',
      required=False,
      choices=['PER_USE', 'PACKAGE'],
      default='PER_USE',
      help=('First Generation instances only. The pricing plan for this '
            'instance.'))
  # TODO(b/31989340): add remote completion
  # TODO(b/73362466): Make zone and region mutually exclusive.
  parser.add_argument(
      '--region',
      required=False,
      default='us-central',
      help=('The regional location (e.g. asia-east1, us-east1). See the full '
            'list of regions at '
            'https://cloud.google.com/sql/docs/instance-locations.'))
  parser.add_argument(
      '--replica-type',
      choices=['READ', 'FAILOVER'],
      help='The type of replica to create.')
  flags.AddReplication(parser)
  parser.add_argument(
      '--require-ssl',
      required=False,
      action='store_true',
      default=None,
      help='Specified if users connecting over IP must use SSL.')
  flags.AddStorageAutoIncrease(parser)
  flags.AddStorageSize(parser)
  parser.add_argument(
      '--storage-type',
      required=False,
      choices=['SSD', 'HDD'],
      default=None,
      help='The storage type for the instance. The default is SSD.')
  parser.add_argument(
      '--tier',
      '-t',
      required=False,
      help=('The tier for this instance. For Second Generation instances, '
            'TIER is the instance\'s machine type (e.g., db-n1-standard-1). '
            'For PostgreSQL instances, only shared-core machine types '
            '(e.g., db-f1-micro) apply. The default tier is db-n1-standard-1. '
            'A complete list of tiers is available here: '
            'https://cloud.google.com/sql/pricing'))


def RunBaseCreateCommand(args, release_track):
  """Creates a new Cloud SQL instance.

  Args:
    args: argparse.Namespace, The arguments that this command was invoked
        with.
    release_track: base.ReleaseTrack, the release track that this was run under.

  Returns:
    A dict object representing the operations resource describing the create
    operation if the create was successful.
  Raises:
    HttpException: A http error response was received while executing api
        request.
  """
  client = common_api_util.SqlClient(common_api_util.API_VERSION_DEFAULT)
  sql_client = client.sql_client
  sql_messages = client.sql_messages

  validate.ValidateInstanceName(args.instance)
  instance_ref = client.resource_parser.Parse(
      args.instance,
      params={'project': properties.VALUES.core.project.GetOrFail},
      collection='sql.instances')

  # Get the region, tier, and database version from the master if these fields
  # are not specified.
  # TODO(b/64266672): Remove once API does not require these fields.
  if args.IsSpecified('master_instance_name'):
    master_instance_ref = client.resource_parser.Parse(
        args.master_instance_name,
        params={'project': properties.VALUES.core.project.GetOrFail},
        collection='sql.instances')
    try:
      master_instance_resource = sql_client.instances.Get(
          sql_messages.SqlInstancesGetRequest(
              project=instance_ref.project,
              instance=master_instance_ref.instance))
    except apitools_exceptions.HttpError as error:
      # TODO(b/64292220): Remove once API gives helpful error message.
      log.debug('operation : %s', str(master_instance_ref))
      exc = exceptions.HttpException(error)
      if resource_property.Get(exc.payload.content,
                               resource_lex.ParseKey('error.errors[0].reason'),
                               None) == 'notAuthorized':
        msg = ('You are either not authorized to access the master instance or '
               'it does not exist.')
        raise exceptions.HttpException(msg)
      raise
    if not args.IsSpecified('region'):
      args.region = master_instance_resource.region
    if not args.IsSpecified('database_version'):
      args.database_version = master_instance_resource.databaseVersion
    if not args.IsSpecified('tier') and master_instance_resource.settings:
      args.tier = master_instance_resource.settings.tier

  instance_resource = (
      command_util.InstancesV1Beta4.ConstructCreateInstanceFromArgs(
          sql_messages,
          args,
          instance_ref=instance_ref,
          release_track=release_track))

  if args.pricing_plan == 'PACKAGE':
    console_io.PromptContinue(
        'Charges will begin accruing immediately. Really create Cloud '
        'SQL instance?', cancel_on_no=True)

  operation_ref = None
  try:
    result_operation = sql_client.instances.Insert(instance_resource)

    operation_ref = client.resource_parser.Create(
        'sql.operations',
        operation=result_operation.name,
        project=instance_ref.project)

    if args.async:
      if not args.IsSpecified('format'):
        args.format = 'default'
      return sql_client.operations.Get(
          sql_messages.SqlOperationsGetRequest(
              project=operation_ref.project,
              operation=operation_ref.operation))

    operations.OperationsV1Beta4.WaitForOperation(
        sql_client, operation_ref, 'Creating Cloud SQL instance')

    log.CreatedResource(instance_ref)

    new_resource = sql_client.instances.Get(
        sql_messages.SqlInstancesGetRequest(
            project=instance_ref.project, instance=instance_ref.instance))
    return new_resource
  except apitools_exceptions.HttpError as error:
    log.debug('operation : %s', str(operation_ref))
    exc = exceptions.HttpException(error)
    if resource_property.Get(exc.payload.content,
                             resource_lex.ParseKey('error.errors[0].reason'),
                             None) == 'errorMaxInstancePerLabel':
      msg = resource_property.Get(exc.payload.content,
                                  resource_lex.ParseKey('error.message'),
                                  None)
      raise exceptions.HttpException(msg)
    raise


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Create(base.Command):
  """Creates a new Cloud SQL instance."""

  def Run(self, args):
    return RunBaseCreateCommand(args, self.ReleaseTrack())

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command."""
    AddBaseArgs(parser)


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class CreateBeta(base.Command):
  """Creates a new Cloud SQL instance."""

  def Run(self, args):
    return RunBaseCreateCommand(args, self.ReleaseTrack())

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command."""
    AddBaseArgs(parser)
    flags.AddInstanceResizeLimit(parser)
    labels_util.AddCreateLabelsFlags(parser)

    # Group for creating external primary instances.
    external_master_group = parser.add_group(
        required=False,
        help='Options for creating a wrapper for an external data source.')
    external_master_group.add_argument(
        '--source-ip-address',
        required=True,
        type=compute_utils.IPV4Argument,
        help=('Public IP address used to connect to and replicate from '
              'the external data source.'))
    external_master_group.add_argument(
        '--source-port',
        type=arg_parsers.BoundedInt(lower_bound=1, upper_bound=65535),
        # Default MySQL port number.
        default=3306,
        help=('Port number used to connect to and replicate from the '
              'external data source.'))

    # Group for creating replicas of external primary instances.
    internal_replica_group = parser.add_group(
        required=False,
        help=('Options for creating an internal replica of an external data '
              'source.'))
    internal_replica_group.add_argument(
        '--master-username',
        required=True,
        help='Name of the replication user on the external data source.')

    # TODO(b/78648703): Make group required when mutex required status is fixed.
    # For entering the password of the replication user of an external primary.
    master_password_group = internal_replica_group.add_group(
        'Password group.', mutex=True)
    master_password_group.add_argument(
        '--master-password',
        help='Password of the replication user on the external data source.')
    master_password_group.add_argument(
        '--prompt-for-master-password',
        action='store_true',
        help=('Prompt for the password of the replication user on the '
              'external data source. The password is all typed characters up '
              'to but not including the RETURN or ENTER key.'))
    internal_replica_group.add_argument(
        '--master-dump-file-path',
        required=True,
        type=storage_util.ObjectReference.FromArgument,
        help=('Path to the MySQL dump file in Google Cloud Storage from '
              'which the seed import is made. The URI is in the form '
              'gs://bucketName/fileName. Compressed gzip files (.gz) are '
              'also supported.'))

    # For specifying SSL certs for connecting to an external primary.
    credential_group = internal_replica_group.add_group(
        'Client and server credentials.', required=False)
    credential_group.add_argument(
        '--master-ca-certificate-path',
        required=True,
        help=('Path to a file containing the X.509v3 (RFC5280) PEM encoded '
              'certificate of the CA that signed the external data source\'s '
              'certificate.'))

    # For specifying client certs for connecting to an external primary.
    client_credential_group = credential_group.add_group(
        'Client credentials.', required=False)
    client_credential_group.add_argument(
        '--client-certificate-path',
        required=True,
        help=('Path to a file containing the X.509v3 (RFC5280) PEM encoded '
              'certificate that will be used by the replica to authenticate '
              'against the external data source.'))
    client_credential_group.add_argument(
        '--client-key-path',
        required=True,
        help=('Path to a file containing the unencrypted PKCS#1 or PKCS#8 '
              'PEM encoded private key associated with the '
              'clientCertificate.'))
