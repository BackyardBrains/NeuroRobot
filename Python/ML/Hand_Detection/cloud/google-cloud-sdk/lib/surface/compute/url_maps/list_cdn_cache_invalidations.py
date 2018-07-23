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

"""Command for listing Cloud CDN cache invalidations."""

from __future__ import absolute_import
from __future__ import unicode_literals
import sys

from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import constants
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.core import properties
from googlecloudsdk.core.resource import resource_projector


class ListCacheInvalidations(base.ListCommand):
  """List Cloud CDN cache invalidations for a URL map."""

  detailed_help = {
      'DESCRIPTION': """\
List Cloud CDN cache invalidations for a URL map. A cache invalidation instructs
Cloud CDN to stop using cached content. You can list invalidations to check
which have completed.
""",
  }

  @staticmethod
  def _Flags(parser):
    parser.add_argument(
        '--limit',
        type=arg_parsers.BoundedInt(1, sys.maxsize, unlimited=True),
        help='The maximum number of invalidations to list.')

  @staticmethod
  def Args(parser):
    parser.display_info.AddFormat("""\
        table(
          description,
          operation_http_status():label=HTTP_STATUS,
          status,
          insertTime:label=TIMESTAMP
        )""")
    parser.add_argument('urlmap', help='The name of the URL map.')

  def GetUrlMapGetRequest(self, client, args):
    return (
        client.apitools_client.urlMaps,
        'Get',
        client.messages.ComputeUrlMapsGetRequest(
            project=properties.VALUES.core.project.GetOrFail(),
            urlMap=args.urlmap))

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    args.uri = None
    get_request = self.GetUrlMapGetRequest(client, args)

    objects = client.MakeRequests([get_request])
    urlmap_id = objects[0].id
    filter_expr = ('(operationType eq invalidateCache) (targetId eq '
                   '{urlmap_id})').format(urlmap_id=urlmap_id)
    max_results = args.limit or constants.MAX_RESULTS_PER_PAGE
    project = properties.VALUES.core.project.GetOrFail()
    requests = [(client.apitools_client.globalOperations, 'AggregatedList',
                 client.apitools_client.globalOperations.GetRequestType(
                     'AggregatedList')(
                         filter=filter_expr,
                         maxResults=max_results,
                         orderBy='creationTimestamp desc',
                         project=project))]
    return resource_projector.MakeSerializable(
        client.MakeRequests(requests=requests))
