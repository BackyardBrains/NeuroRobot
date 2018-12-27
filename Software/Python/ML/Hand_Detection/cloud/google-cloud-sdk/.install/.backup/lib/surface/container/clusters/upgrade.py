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

"""Upgrade cluster command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions

from googlecloudsdk.api_lib.container import api_adapter
from googlecloudsdk.api_lib.container import util
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.command_lib.container import container_command_util
from googlecloudsdk.command_lib.container import flags
from googlecloudsdk.core import log
from googlecloudsdk.core.console import console_attr
from googlecloudsdk.core.console import console_io
from googlecloudsdk.core.util.semver import SemVer


class UpgradeHelpText(object):
  """Upgrade available help text messages."""
  UPGRADE_AVAILABLE = '''
* - There is an upgrade available for your cluster(s).
'''

  SUPPORT_ENDING = '''
** - The current version of your cluster(s) will soon be out of support, please upgrade.
'''

  UNSUPPORTED = '''
*** - The current version of your cluster(s) is unsupported, please upgrade.
'''

  UPGRADE_COMMAND = '''
To upgrade nodes to the latest available version, run
  $ gcloud container clusters upgrade {name}'''


class VersionVerifier(object):
  """Compares the cluster and master versions for upgrade availablity."""
  UP_TO_DATE = 0
  UPGRADE_AVAILABLE = 1
  SUPPORT_ENDING = 2
  UNSUPPORTED = 3

  def Compare(self, current_master_version, current_cluster_version):
    """Compares the cluster and master versions and returns an enum."""
    # TODO(b/36051978):update the if condition when we roll the master version
    if current_master_version == current_cluster_version:
      return self.UP_TO_DATE
    master_version = SemVer(current_master_version)
    cluster_version = SemVer(current_cluster_version)
    major, minor, _ = master_version.Distance(cluster_version)
    if major != 0 or minor > 2:
      return self.UNSUPPORTED
    elif minor > 1:
      return self.SUPPORT_ENDING
    else:
      return self.UPGRADE_AVAILABLE


def _Args(parser):
  """Register flags for this command.

  Args:
    parser: An argparse.ArgumentParser-like object. It is mocked out in order
        to capture some information, but behaves like an ArgumentParser.
  """
  parser.add_argument(
      'name',
      metavar='NAME',
      help='The name of the cluster to upgrade.')
  flags.AddClusterVersionFlag(
      parser,
      help="""\
The Kubernetes release version to which to upgrade the cluster's nodes.

When upgrading nodes, the minor version (*X.Y*.Z) must be no greater than the
cluster master's minor version (i.e. if the master's version is 1.2.34, the
nodes cannot be upgraded to 1.3.45). For any minor version, only the latest
patch version (X.Y.*Z*) is allowed (i.e. if there exists a version 1.2.34, the
nodes cannot be upgraded to 1.2.33). Omit to upgrade to the same version as the
master.

When upgrading master, the only valid value is the latest supported version.
Omit to have the server automatically select the latest version.

You can find the list of allowed versions for upgrades by running:

  $ gcloud container get-server-config
""")
  parser.add_argument(
      '--node-pool',
      help='The node pool to upgrade.')
  parser.add_argument(
      '--master',
      help='Upgrade the cluster\'s master to the latest version of Kubernetes'
      ' supported on Kubernetes Engine. Nodes cannot be upgraded at the same'
      ' time as the master.',
      action='store_true')
  flags.AddAsyncFlag(parser)
  flags.AddImageTypeFlag(parser, 'cluster/node pool')
  flags.AddImageFlag(parser, hidden=True)
  flags.AddImageProjectFlag(parser, hidden=True)


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Upgrade(base.Command):
  """Upgrade the Kubernetes version of an existing container cluster."""

  @staticmethod
  def Args(parser):
    _Args(parser)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
        command invocation.

    Returns:
      Some value that we want to have printed later.
    """
    adapter = self.context['api_adapter']
    location_get = self.context['location_get']
    location = location_get(args)
    cluster_ref = adapter.ParseCluster(args.name, location)
    concurrent_node_count = getattr(args, 'concurrent_node_count', None)

    try:
      cluster = adapter.GetCluster(cluster_ref)
    except (exceptions.HttpException,
            apitools_exceptions.HttpForbiddenError,
            util.Error) as error:
      log.warning(('Problem loading details of cluster to upgrade:\n\n{}\n\n' +
                   'You can still attempt to upgrade the cluster.\n')
                  .format(console_attr.SafeText(error)))
      cluster = None

    upgrade_message = container_command_util.ClusterUpgradeMessage(
        name=args.name,
        cluster=cluster,
        master=args.master,
        node_pool_name=args.node_pool,
        new_version=args.cluster_version,
        concurrent_node_count=concurrent_node_count)

    console_io.PromptContinue(
        message=upgrade_message,
        throw_if_unattended=True,
        cancel_on_no=True)

    options = api_adapter.UpdateClusterOptions(
        version=args.cluster_version,
        update_master=args.master,
        update_nodes=(not args.master),
        node_pool=args.node_pool,
        image_type=args.image_type,
        image=args.image,
        image_project=args.image_project,
        concurrent_node_count=concurrent_node_count)

    try:
      op_ref = adapter.UpdateCluster(cluster_ref, options)
    except apitools_exceptions.HttpError as error:
      raise exceptions.HttpException(error, util.HTTP_ERROR_FORMAT)

    if not args.async:
      adapter.WaitForOperation(
          op_ref, 'Upgrading {0}'.format(cluster_ref.clusterId))

      log.UpdatedResource(cluster_ref)

Upgrade.detailed_help = {
    'DESCRIPTION': """\
      Upgrades the Kubernetes version of an existing container cluster.

      This command upgrades the Kubernetes version of the *nodes* or *master* of
      a cluster. Note that the Kubernetes version of the cluster's *master* is
      also periodically upgraded automatically as new releases are available.

      If desired cluster version is omitted, *node* upgrades default to the
      current *master* version and *master* upgrades default to the latest
      supported version.

      *By running this command, all of the cluster's nodes will be deleted and*
      *recreated one at a time.* While persistent Kubernetes resources, such as
      pods backed by replication controllers, will be rescheduled onto new nodes,
      a small cluster may experience a few minutes where there are insufficient
      nodes available to run all of the scheduled Kubernetes resources.

      *Please ensure that any data you wish to keep is stored on a persistent*
      *disk before upgrading the cluster.* Ephemeral Kubernetes resources--in
      particular, pods without replication controllers--will be lost, while
      persistent Kubernetes resources will get rescheduled.
    """,
    'EXAMPLES': """\
      Upgrade the nodes of <cluster> to the Kubernetes version of the cluster's
      master.

        $ {command} <cluster>

      Upgrade the nodes of <cluster> to Kubernetes version x.y.z:

        $ {command} <cluster> --cluster-version "x.y.z"

      Upgrade the master of <cluster> to the latest supported version:

        $ {command} <cluster> --master"
""",
}


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class UpgradeBeta(Upgrade):
  """Upgrade the Kubernetes version of an existing container cluster."""

  @staticmethod
  def Args(parser):
    _Args(parser)


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class UpgradeAlpha(Upgrade):
  """Upgrade the Kubernetes version of an existing container cluster."""

  @staticmethod
  def Args(parser):
    _Args(parser)
    flags.AddConcurrentNodeCountFlag(parser)
