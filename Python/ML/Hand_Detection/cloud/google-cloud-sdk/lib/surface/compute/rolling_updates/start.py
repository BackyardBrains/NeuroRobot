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

"""rolling-updates start command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions

from googlecloudsdk.api_lib.compute import rolling_updates_util as updater_util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import log
from googlecloudsdk.core import properties
from googlecloudsdk.core import resources


class Start(base.Command):
  """Starts a new rolling update."""

  @staticmethod
  def Args(parser):
    """Args is called by calliope to gather arguments for this command.

    Args:
      parser: An argparse parser that you can use to add arguments that go
          on the command line after this command. Positional arguments are
          allowed.
    """
    parser.add_argument(
        '--group', help='Instance group name.', required=True)
    parser.add_argument(
        '--action',
        help="""\
        Action to be performed on each instance. Currently only 'RECREATE' is
        supported.
        """,
        choices=['RECREATE'], default='RECREATE')
    parser.add_argument(
        '--template', required=True,
        help='Name of the Compute Engine instance template resource.')
    parser.add_argument(
        '--auto-pause-after-instances', type=int,
        help="""\
        Number of instances after which the update will be automatically paused.
        """)
    parser.add_argument(
        '--max-num-concurrent-instances', type=int,
        help='Maximum number of instances that can be updated simultaneously.')
    parser.add_argument(
        '--min-instance-update-time', type=arg_parsers.Duration(),
        help="""\
        Specifies minimum amount of time we will spend on updating single
        instance, measuring at the start of the first update action (currently
        only 'RECREATE' call). If actual instance update takes less time we will
        simply sleep before proceeding with next instance.
        See $ gcloud topic datetimes for information on duration formats.
        """)
    parser.add_argument(
        '--instance-startup-timeout', type=arg_parsers.Duration(),
        help="""\
        Maximum amount of time we will wait after finishing all steps until
        instance is in *RUNNING* state. If this deadline is exceeded instance
        update is considered as failed.
        See $ gcloud topic datetimes for information on duration formats.
        """)
    parser.add_argument(
        '--max-num-failed-instances', type=int,
        help="""\
        Maximum number of instance updates that can fail without failing the
        group update. Instance update is considered failed if any of its
        update actions (currently only 'RECREATE' call) failed with permanent
        failure, or if after finishing all update actions this instance is not
        running.
        """)

  def Run(self, args):
    """Run 'rolling-updates start'.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Raises:
      HttpException: An http error response was received while executing api
          request.
      ToolException: An error other than http error occurred while executing
          the command.
    """
    client = updater_util.GetApiClientInstance()
    messages = updater_util.GetApiMessages()

    request = messages.ReplicapoolupdaterRollingUpdatesInsertRequest(
        project=properties.VALUES.core.project.Get(required=True),
        zone=properties.VALUES.compute.zone.Get(required=True),
        rollingUpdate=self._PrepareUpdate(args))

    try:
      operation = client.rollingUpdates.Insert(request)
      operation_ref = resources.REGISTRY.Parse(
          operation.name,
          params={
              'project': properties.VALUES.core.project.GetOrFail,
              'zone': properties.VALUES.compute.zone.GetOrFail,
          },
          collection='replicapoolupdater.zoneOperations')
      result = updater_util.WaitForOperation(
          client, operation_ref, 'Starting a new update')
      if result:
        log.status.write('Started [{0}].\n'.format(operation.targetLink))
      else:
        raise exceptions.ToolException(
            'could not start [{0}]'.format(operation.targetLink))

    except apitools_exceptions.HttpError as error:
      raise exceptions.HttpException(error)

  def _PrepareUpdate(self, args):
    """Creates an update object based on user-provided flags.

    Args:
      args: argparse.Namespace, The arguments that this command was invoked
          with.

    Returns:
      Update, an update object prepared to be used by Insert method.

    Raises:
      SystemExit: Incorrect command line flags.
    """
    messages = updater_util.GetApiMessages()

    policy = messages.RollingUpdate.PolicyValue()
    if args.auto_pause_after_instances:
      policy.autoPauseAfterInstances = args.auto_pause_after_instances
    if args.max_num_concurrent_instances:
      policy.maxNumConcurrentInstances = args.max_num_concurrent_instances
    if args.min_instance_update_time:
      policy.minInstanceUpdateTimeSec = args.min_instance_update_time
    if args.instance_startup_timeout:
      policy.instanceStartupTimeoutSec = args.instance_startup_timeout
    if args.max_num_failed_instances:
      policy.maxNumFailedInstances = args.max_num_failed_instances

    group_ref = resources.REGISTRY.Parse(
        args.group,
        params={
            'project': properties.VALUES.core.project.GetOrFail,
            'zone': properties.VALUES.compute.zone.GetOrFail,
        },
        collection='compute.instanceGroupManagers')
    template_ref = resources.REGISTRY.Parse(
        args.template,
        params={'project': properties.VALUES.core.project.GetOrFail},
        collection='compute.instanceTemplates')

    return messages.RollingUpdate(
        instanceGroupManager=group_ref.SelfLink(),
        actionType=args.action,
        instanceTemplate=template_ref.SelfLink(),
        policy=policy)


Start.detailed_help = {
    'brief': 'Starts a new rolling update.',
    'DESCRIPTION': """\
        A rolling update causes the service to gradually update your \
        existing instances.

        You can increase the number of instances updated simultaneously with \
        the --max-num-concurrent-instances flag.

        If you are not sure you want to apply an update to all existing \
        instances, you can use the --auto-pause-after-instances flag and the \
        update will automatically be paused after updating the number of \
        instances specified. Afterwards, you can decide whether to cancel or \
        continue the update.

        In case you notice your managed instance group misbehaving due to the \
        new template, you can roll back the update. This will stop the update \
        from being applied to more instances, and instances already created \
        with the new template will be recreated with the last template applied \
        before the current update.
        """,
}
