# Copyright 2017 Google Inc. All Rights Reserved.
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
"""Surface for creating an App Engine domain mapping."""

from __future__ import absolute_import
from googlecloudsdk.api_lib.app.api import appengine_domains_api_client as api_client
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.app import domains_util
from googlecloudsdk.command_lib.app import flags
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Create(base.CreateCommand):
  """Creates a domain mapping."""

  detailed_help = {
      'DESCRIPTION':
          '{description}',
      'EXAMPLES':
          """\
          To create a new App Engine new domain mapping, run:

              $ {command} '*.example.com' \
                    --certificate-id=1234
          """,
  }

  @staticmethod
  def Args(parser):
    flags.DOMAIN_FLAG.AddToParser(parser)
    flags.AddCertificateIdFlag(parser, include_no_cert=False)
    parser.display_info.AddFormat('default(id, resourceRecords)')

  def Run(self, args):
    return self.Create(args)

  def Create(self, args, enable_certificate_management=False):
    client = api_client.GetApiClientForTrack(self.ReleaseTrack())

    if enable_certificate_management:
      domains_util.ValidateCertificateArgs(
          args.certificate_id, args.certificate_management)

      if not args.certificate_management:
        if not args.certificate_id:
          args.certificate_management = 'automatic'
        else:
          args.certificate_management = 'manual'

      management_type = domains_util.ParseCertificateManagement(
          client.messages, args.certificate_management)

      mapping = client.CreateDomainMapping(args.domain,
                                           args.certificate_id,
                                           management_type)
    else:
      mapping = client.CreateDomainMapping(args.domain,
                                           args.certificate_id)
    log.CreatedResource(args.domain)

    log.status.Print(
        'Please add the following entries to your domain registrar.'
        ' DNS changes can require up to 24 hours to take effect.')
    return mapping


@base.ReleaseTracks(base.ReleaseTrack.ALPHA,
                    base.ReleaseTrack.BETA)
class CreateBeta(Create):
  """Creates a domain mapping."""

  detailed_help = {
      'DESCRIPTION':
          '{description}',
      'EXAMPLES':
          """\
          To create a new App Engine new domain mapping with an automatically
          managed certificate, run:

              $ {command} 'example.com'

          To create a domain with a manual certificate, run:

              $ {command} '*.example.com' \
                  --certificate-management=manual --certificate-id=1234

          Note: managed certificates do not support wildcard domain mappings.

          To create a domain with no associated certificate, run:

              $ {command} '*.example.com' \
                  --certificate-management=manual
          """,
  }

  @staticmethod
  def Args(parser):
    super(CreateBeta, CreateBeta).Args(parser)
    flags.AddCertificateManagementFlag(parser)

  def Run(self, args):
    return self.Create(args, enable_certificate_management=True)
