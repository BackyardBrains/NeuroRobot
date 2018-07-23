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
"""Command for setting autohealing policy of managed instance group."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import managed_instance_groups_utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute import scope as compute_scope
from googlecloudsdk.command_lib.compute.health_checks import flags as health_checks_flags
from googlecloudsdk.command_lib.compute.instance_groups import flags as instance_groups_flags
from googlecloudsdk.command_lib.compute.managed_instance_groups import auto_healing_utils


@base.ReleaseTracks(base.ReleaseTrack.BETA, base.ReleaseTrack.ALPHA)
class SetAutohealing(base.Command):
  """Set autohealing policy for managed instance group.

    *{command}* updates the autohealing policy for an existing managed
  instance group.

  If --http-health-check or --https-health-check is specified, the resulting
  autohealing policy will be triggered by the health-check i.e. the autohealing
  action (RECREATE) on an instance will be performed if the health-check signals
  that the instance is UNHEALTHY. If neither --http-health-check nor
  --https-health-check is specified, the resulting autohealing policy will be
  triggered by instance's status i.e. the autohealing action (RECREATE) on an
  instance will be performed if the instance.status is not RUNNING.
  --initial-delay specifies the length of the period during which IGM will
  refrain from autohealing the instance even if the instance is reported as not
  RUNNING or UNHEALTHY. This value must be from range [0, 3600].
  """

  HEALTH_CHECK_ARG = health_checks_flags.HealthCheckArgument(
      '', '--health-check', required=False)

  @classmethod
  def Args(cls, parser):
    health_check_group = parser.add_mutually_exclusive_group()
    cls.HEALTH_CHECK_ARG.AddArgument(health_check_group)
    auto_healing_utils.AddAutohealingArgs(
        parser=parser, health_check_group=health_check_group)
    instance_groups_flags.MULTISCOPE_INSTANCE_GROUP_MANAGER_ARG.AddArgument(
        parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    igm_ref = (instance_groups_flags.MULTISCOPE_INSTANCE_GROUP_MANAGER_ARG.
               ResolveAsResource)(
                   args, holder.resources,
                   default_scope=compute_scope.ScopeEnum.ZONE,
                   scope_lister=flags.GetDefaultScopeLister(client))
    health_check = managed_instance_groups_utils.GetHealthCheckUri(
        holder.resources, args, self.HEALTH_CHECK_ARG)
    auto_healing_policies = (
        managed_instance_groups_utils.CreateAutohealingPolicies(
            client.messages, health_check, args.initial_delay))

    managed_instance_groups_utils.ValidateAutohealingPolicies(
        auto_healing_policies)

    if igm_ref.Collection() == 'compute.instanceGroupManagers':
      service = client.apitools_client.instanceGroupManagers
      request = (
          client.messages.
          ComputeInstanceGroupManagersSetAutoHealingPoliciesRequest(
              project=igm_ref.project,
              zone=igm_ref.zone,
              instanceGroupManager=igm_ref.Name(),
              instanceGroupManagersSetAutoHealingRequest=(
                  client.messages.InstanceGroupManagersSetAutoHealingRequest(
                      autoHealingPolicies=auto_healing_policies))))
    else:
      service = client.apitools_client.regionInstanceGroupManagers
      request = (
          client.messages.
          ComputeRegionInstanceGroupManagersSetAutoHealingPoliciesRequest(
              project=igm_ref.project,
              region=igm_ref.region,
              instanceGroupManager=igm_ref.Name(),
              regionInstanceGroupManagersSetAutoHealingRequest=(
                  client.messages.
                  RegionInstanceGroupManagersSetAutoHealingRequest(
                      autoHealingPolicies=auto_healing_policies))))

    return client.MakeRequests([(service, 'SetAutoHealingPolicies', request)])
