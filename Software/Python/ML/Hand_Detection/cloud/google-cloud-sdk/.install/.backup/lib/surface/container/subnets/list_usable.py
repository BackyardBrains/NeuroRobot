# Copyright 2018 Google Inc. All Rights Reserved.
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

"""List usable subnets command."""
from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import exceptions as apitools_exceptions

from googlecloudsdk.api_lib.container import util
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import properties
from googlecloudsdk.core import resources


def _GetUriFunction(resource):
  return resources.REGISTRY.ParseRelativeName(resource.subnetwork,
                                              'compute.subnetworks').SelfLink()


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class ListUsable(base.ListCommand):
  r"""Returns subnets usable for cluster creation in a specific project.

      Usability of subnetworks for cluster creation is dependent on the IAM
      policy of the project's Google Kubernetes Engine Service Account. Use the
      *--project* flag to evaluate subnet usability in different projects. This
      list may differ from the list returned by Google Compute Engine's
      `list-usable` command which returns subnets only usable by the caller.

      To show subnetworks shared from a Shared-VPC host project, use
      *--network-project* to specify the project which owns the subnetworks.

      ## EXAMPLES

      List all subnetworks usable for cluster creation in project `my-project`.

          $ gcloud container subnets list-usable \
            --project my-project

      List all subnetworks existing in project `my-shared-host-project` usable
      for cluster creation in project `my-service-project`.

          $ gcloud container subnets list-usable \
             --project my-service-project \
             --network-project my-shared-host-project

  """

  @staticmethod
  def Args(parser):
    """Register flags for this command.

    Args:
      parser: An argparse.ArgumentParser-like object. It is mocked out in order
          to capture some information, but behaves like an ArgumentParser.
    """

    parser.add_argument(
        '--network-project',
        help="""\
        The project owning the subnetworks returned. This field is translated
        into the expression `networkProjectId=[PROJECT_ID]` and ANDed to
        the `--filter` flag value.

        Defaults to the *--project* value.
""")

    display_format = 'table({fields})'.format(fields=','.join([
        'subnetwork.segment(-5):label=PROJECT',
        'subnetwork.segment(-3):label=REGION',
        'network.segment(-1):label=NETWORK',
        'subnetwork.segment(-1):label=SUBNET',
        'ipCidrRange:label=RANGE',
    ]))
    parser.display_info.AddFormat(display_format)
    parser.display_info.AddUriFunc(_GetUriFunction)

  def Run(self, args):
    """This is what gets called when the user runs this command.

    Args:
      args: an argparse namespace. All the arguments that were provided to this
        command invocation.

    Returns:
      Some value that we want to have printed later.
    """
    adapter = self.context['api_adapter']
    project_ref = adapter.registry.Create('container.projects',
                                          projectsId=properties.VALUES.core
                                          .project.GetOrFail())

    try:
      return adapter.ListUsableSubnets(project_ref,
                                       args.network_project,
                                       args.filter).subnetworks
    except apitools_exceptions.HttpError as error:
      raise exceptions.HttpException(error, util.HTTP_ERROR_FORMAT)
