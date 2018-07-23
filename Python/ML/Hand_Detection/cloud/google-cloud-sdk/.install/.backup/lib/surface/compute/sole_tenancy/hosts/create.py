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
"""Command for creating sole-tenancy hosts."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute import scope
from googlecloudsdk.command_lib.compute.sole_tenancy.hosts import flags as hosts_flags


@base.Deprecate(
    error=('New host creation is disabled. Please use '
           '`gcloud alpha compute sole-tenancy node-groups` instead.'))
class Create(base.CreateCommand):
  """Create Google Compute Engine sole-tenancy hosts."""

  @staticmethod
  def Args(parser):
    parser.display_info.AddFormat(hosts_flags.DEFAULT_LIST_FORMAT)
    Create.HOST_ARG = hosts_flags.MakeHostArg(plural=True)
    Create.HOST_ARG.AddArgument(parser, operation_type='create')
    parser.add_argument(
        '--description',
        help='Specifies a textual description of the hosts.')
    parser.add_argument(
        '--host-type',
        help=('Specifies a type of the hosts. Type of a host determines '
              'resources available to instances running on it.'))

  def _CreateRequest(self, messages, host_ref, description, host_type):
    return messages.ComputeHostsInsertRequest(
        host=messages.Host(
            name=host_ref.Name(),
            description=description,
            hostType=host_type),
        project=host_ref.project,
        zone=host_ref.zone)

  def Run(self, args):
    """Returns a list of requests necessary for adding hosts."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    host_refs = Create.HOST_ARG.ResolveAsResource(
        args, holder.resources,
        default_scope=scope.ScopeEnum.ZONE,
        scope_lister=flags.GetDefaultScopeLister(client))
    if args.host_type:
      host_type_ref = holder.resources.Parse(
          args.host_type, collection='compute.hostTypes',
          params={
              'project': host_refs[0].project,
              'zone': host_refs[0].zone
          })
      host_type_url = host_type_ref.SelfLink()
    else:
      host_type_url = None
    host_properties = {
        'description': args.description,
        'host_type': host_type_url,
    }
    return client.MakeRequests([(client.apitools_client.hosts,
                                 'Insert', self._CreateRequest(
                                     client.messages, ref, **host_properties))
                                for ref in host_refs])
