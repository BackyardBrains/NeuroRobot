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
"""gcloud dns dnskeys list command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.dns import dns_keys
from googlecloudsdk.core import properties


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class ListBeta(base.ListCommand):
  """View the list of all your DNSKEY records."""

  detailed_help = dns_keys.LIST_HELP

  @staticmethod
  def Args(parser):
    dns_keys.AddListFlags(parser)

  def Run(self, args):
    keys = dns_keys.Keys.FromApiVersion('v1beta2')
    return keys.List(args.zone, properties.VALUES.core.project.GetOrFail)


@base.ReleaseTracks(base.ReleaseTrack.GA)
class List(base.ListCommand):
  """View the list of all your DNSKEY records."""

  detailed_help = dns_keys.LIST_HELP

  @staticmethod
  def Args(parser):
    dns_keys.AddListFlags(parser, hide_short_zone_flag=True)

  def Run(self, args):
    keys = dns_keys.Keys.FromApiVersion('v1')
    return keys.List(args.zone, properties.VALUES.core.project.GetOrFail)
