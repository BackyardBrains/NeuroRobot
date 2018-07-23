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

"""The main command group for cloud container."""

from __future__ import absolute_import
from __future__ import unicode_literals
import argparse
from googlecloudsdk.api_lib.container import api_adapter
from googlecloudsdk.calliope import actions
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.container import constants
from googlecloudsdk.command_lib.container import container_command_util
from googlecloudsdk.core import log
from googlecloudsdk.core import properties


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Container(base.Group):
  """Deploy and manage clusters of machines for running containers.

  The gcloud container command group lets you create and manage Google
  Kubernetes Engine containers and clusters.

  Kubernetes Engine is a cluster manager and orchestration system for
  running your Docker containers. Kubernetes Engine schedules your containers
  into the cluster and manages them automatically based on requirements you
  define, such as CPU and memory.

  More information on Kubernetes Engine can be found here:
  https://cloud.google.com/kubernetes-engine and detailed documentation
  can be found here: https://cloud.google.com/kubernetes-engine/docs/
  """

  @staticmethod
  def Args(parser):
    """Add arguments to the parser.

    Args:
      parser: argparse.ArgumentParser, This is a standard argparser parser with
        which you can register arguments.  See the public argparse documentation
        for its capabilities.
    """
    parser.add_argument(
        '--api-version', hidden=True, help='THIS ARGUMENT NEEDS HELP TEXT.',
        action=actions.StoreProperty(
            properties.VALUES.api_client_overrides.container))

  def Filter(self, context, args):
    """Modify the context that will be given to this group's commands when run.

    Args:
      context: {str:object}, A set of key-value pairs that can be used for
          common initialization among commands.
      args: argparse.Namespace: The same namespace given to the corresponding
          .Run() invocation.

    Returns:
      The refined command context.
    """
    base.DisableUserProjectQuota()
    context['api_adapter'] = api_adapter.NewAPIAdapter('v1')
    return context


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class ContainerBeta(Container):
  """Deploy and manage clusters of machines for running containers."""

  def Filter(self, context, args):
    """Modify the context that will be given to this group's commands when run.

    Args:
      context: {str:object}, A set of key-value pairs that can be used for
          common initialization among commands.
      args: argparse.Namespace: The same namespace given to the corresponding
          .Run() invocation.

    Returns:
      The refined command context.
    """
    base.DisableUserProjectQuota()
    if container_command_util.GetUseV1APIProperty():
      api_version = 'v1'
    else:
      api_version = 'v1beta1'
    context['api_adapter'] = api_adapter.NewAPIAdapter(api_version)
    return context


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class ContainerAlpha(Container):
  """Deploy and manage clusters of machines for running containers."""

  def Filter(self, context, args):
    """Modify the context that will be given to this group's commands when run.

    Args:
      context: {str:object}, A set of key-value pairs that can be used for
          common initialization among commands.
      args: argparse.Namespace: The same namespace given to the corresponding
          .Run() invocation.

    Returns:
      The refined command context.
    """
    base.DisableUserProjectQuota()
    if container_command_util.GetUseV1APIProperty():
      api_version = 'v1'
    else:
      api_version = 'v1alpha1'
    context['api_adapter'] = api_adapter.NewAPIAdapter(api_version)
    return context
