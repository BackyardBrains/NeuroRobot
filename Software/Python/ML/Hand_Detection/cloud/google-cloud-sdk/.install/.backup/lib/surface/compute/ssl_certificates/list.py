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
"""Command for listing SSL certificates."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import lister
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.ssl_certificates import flags


def _Args(parser, list_format):
  parser.display_info.AddFormat(list_format)
  lister.AddBaseListerArgs(parser)
  parser.display_info.AddCacheUpdater(flags.SslCertificatesCompleter)


@base.ReleaseTracks(base.ReleaseTrack.GA, base.ReleaseTrack.BETA)
class List(base.ListCommand):
  """List Google Compute Engine SSL certificates."""

  @staticmethod
  def Args(parser):
    _Args(parser, flags.DEFAULT_LIST_FORMAT)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    request_data = lister.ParseNamesAndRegexpFlags(args, holder.resources)

    list_implementation = lister.GlobalLister(
        client, client.apitools_client.sslCertificates)

    return lister.Invoke(request_data, list_implementation)


List.detailed_help = base_classes.GetGlobalListerHelp('SSL certificates')


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class ListAlpha(List):

  @staticmethod
  def Args(parser):
    _Args(parser, flags.ALPHA_LIST_FORMAT)
