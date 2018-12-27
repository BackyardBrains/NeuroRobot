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
"""Command for updating target HTTP proxies."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.target_http_proxies import flags
from googlecloudsdk.command_lib.compute.url_maps import flags as url_map_flags


class Update(base.SilentCommand):
  """Update a target HTTP proxy.

  *{command}* is used to change the URL map of existing
  target HTTP proxies. A target HTTP proxy is referenced
  by one or more forwarding rules which
  define which packets the proxy is responsible for routing. The
  target HTTP proxy in turn points to a URL map that defines the rules
  for routing the requests. The URL map's job is to map URLs to
  backend services which handle the actual requests.
  """

  TARGET_HTTP_PROXY_ARG = None
  URL_MAP_ARG = None

  @classmethod
  def Args(cls, parser):
    cls.TARGET_HTTP_PROXY_ARG = flags.TargetHttpProxyArgument()
    cls.TARGET_HTTP_PROXY_ARG.AddArgument(parser, operation_type='update')
    cls.URL_MAP_ARG = url_map_flags.UrlMapArgumentForTargetProxy()
    cls.URL_MAP_ARG.AddArgument(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    url_map_ref = self.URL_MAP_ARG.ResolveAsResource(args, holder.resources)

    target_http_proxy_ref = self.TARGET_HTTP_PROXY_ARG.ResolveAsResource(
        args, holder.resources)

    request = client.messages.ComputeTargetHttpProxiesSetUrlMapRequest(
        project=target_http_proxy_ref.project,
        targetHttpProxy=target_http_proxy_ref.Name(),
        urlMapReference=client.messages.UrlMapReference(
            urlMap=url_map_ref.SelfLink()))

    return client.MakeRequests([(client.apitools_client.targetHttpProxies,
                                 'SetUrlMap', request)])
