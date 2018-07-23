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
"""Command for deleting sole-tenancy hosts."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.sole_tenancy.hosts import flags


class Delete(base.DeleteCommand):
  """Delete Google Compute Engine sole-tenancy hosts.

  *{command}* deletes one or more Google Compute Engine
  sole-tenancy hosts. Hosts can be deleted only if they are not
  being used by any virtual machine instances.
  """

  @staticmethod
  def Args(parser):
    Delete.HOST_ARG = flags.MakeHostArg(plural=True)
    Delete.HOST_ARG.AddArgument(parser, operation_type='delete')

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    host_refs = Delete.HOST_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(client))

    custom_prompt = ('The following hosts will be deleted. Deleting a host is '
                     'irreversible and any data on the host will be lost.')

    utils.PromptForDeletion(host_refs, 'zone', prompt_title=custom_prompt)

    requests = [(client.apitools_client.hosts, 'Delete',
                 client.messages.ComputeHostsDeleteRequest(**host_ref.AsDict()))
                for host_ref in host_refs]

    return client.MakeRequests(requests)
