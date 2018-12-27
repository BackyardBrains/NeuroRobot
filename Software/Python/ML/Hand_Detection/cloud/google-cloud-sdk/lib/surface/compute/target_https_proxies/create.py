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
"""Command for creating target HTTPS proxies."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import target_proxies_utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.ssl_certificates import (
    flags as ssl_certificates_flags)
from googlecloudsdk.command_lib.compute.ssl_policies import (flags as
                                                             ssl_policies_flags)
from googlecloudsdk.command_lib.compute.target_https_proxies import flags
from googlecloudsdk.command_lib.compute.url_maps import flags as url_map_flags


@base.ReleaseTracks(base.ReleaseTrack.GA)
class CreateGA(base.CreateCommand):
  """Create a target HTTPS proxy.

    *{command}* is used to create target HTTPS proxies. A target
  HTTPS proxy is referenced by one or more forwarding rules which
  define which packets the proxy is responsible for routing. The
  target HTTPS proxy points to a URL map that defines the rules
  for routing the requests. The URL map's job is to map URLs to
  backend services which handle the actual requests. The target
  HTTPS proxy also points to at most 10 SSL certificates used for
  server-side authentication. The target HTTPS proxy can be associated with
  at most one SSL policy.
  """

  SSL_CERTIFICATES_ARG = None
  TARGET_HTTPS_PROXY_ARG = None
  URL_MAP_ARG = None
  SSL_POLICY_ARG = None

  @classmethod
  def Args(cls, parser):
    parser.display_info.AddFormat(flags.DEFAULT_LIST_FORMAT)
    cls.SSL_CERTIFICATES_ARG = (
        ssl_certificates_flags.SslCertificatesArgumentForOtherResource(
            'target HTTPS proxy'))
    cls.SSL_CERTIFICATES_ARG.AddArgument(parser, cust_metavar='SSL_CERTIFICATE')

    cls.TARGET_HTTPS_PROXY_ARG = flags.TargetHttpsProxyArgument()
    cls.TARGET_HTTPS_PROXY_ARG.AddArgument(parser, operation_type='create')

    cls.URL_MAP_ARG = url_map_flags.UrlMapArgumentForTargetProxy(
        proxy_type='HTTPS')
    cls.URL_MAP_ARG.AddArgument(parser)

    cls.SSL_POLICY_ARG = (
        ssl_policies_flags.GetSslPolicyArgumentForOtherResource(
            'HTTPS', required=False))
    cls.SSL_POLICY_ARG.AddArgument(parser)

    parser.add_argument(
        '--description',
        help='An optional, textual description for the target HTTPS proxy.')
    parser.display_info.AddCacheUpdater(flags.TargetHttpsProxiesCompleter)

  def _SendRequests(self, args, quic_override=None):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    url_map_ref = self.URL_MAP_ARG.ResolveAsResource(args, holder.resources)
    ssl_cert_refs = self.SSL_CERTIFICATES_ARG.ResolveAsResource(
        args, holder.resources)
    target_https_proxy_ref = self.TARGET_HTTPS_PROXY_ARG.ResolveAsResource(
        args, holder.resources)
    target_https_proxy = client.messages.TargetHttpsProxy(
        description=args.description,
        name=target_https_proxy_ref.Name(),
        urlMap=url_map_ref.SelfLink(),
        sslCertificates=[ref.SelfLink() for ref in ssl_cert_refs])
    ssl_policy_ref = self.SSL_POLICY_ARG.ResolveAsResource(
        args, holder.resources) if args.ssl_policy else None

    if quic_override:
      target_https_proxy.quicOverride = quic_override

    if ssl_policy_ref:
      target_https_proxy.sslPolicy = ssl_policy_ref.SelfLink()

    request = client.messages.ComputeTargetHttpsProxiesInsertRequest(
        project=target_https_proxy_ref.project,
        targetHttpsProxy=target_https_proxy)

    return client.MakeRequests([(client.apitools_client.targetHttpsProxies,
                                 'Insert', request)])

  def Run(self, args):
    return self._SendRequests(args)


@base.ReleaseTracks(base.ReleaseTrack.ALPHA, base.ReleaseTrack.BETA)
class CreateBeta(CreateGA):
  """Create a target HTTPS proxy.

    *{command}* is used to create target HTTPS proxies. A target
  HTTPS proxy is referenced by one or more forwarding rules which
  define which packets the proxy is responsible for routing. The
  target HTTPS proxy points to a URL map that defines the rules
  for routing the requests. The URL map's job is to map URLs to
  backend services which handle the actual requests. The target
  HTTPS proxy also points to at most 10 SSL certificates used for
  server-side authentication. The target HTTPS proxy can be associated with
  at most one SSL policy.
  """

  @classmethod
  def Args(cls, parser):
    super(CreateBeta, cls).Args(parser)
    target_proxies_utils.AddQuicOverrideCreateArgs(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    messages = holder.client.messages
    quic_override = messages.TargetHttpsProxy.QuicOverrideValueValuesEnum(
        args.quic_override)
    return self._SendRequests(args, quic_override)
