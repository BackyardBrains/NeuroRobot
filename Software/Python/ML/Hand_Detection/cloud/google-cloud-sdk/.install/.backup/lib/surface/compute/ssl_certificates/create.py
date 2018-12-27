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
"""Command for creating SSL certificates."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import file_utils
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.ssl_certificates import flags


@base.ReleaseTracks(base.ReleaseTrack.GA, base.ReleaseTrack.BETA)
class Create(base.CreateCommand):
  """Create a Google Compute Engine SSL certificate.

  *{command}* is used to create SSL certificates which can be used to
  configure a target HTTPS proxy. An SSL certificate consists of a
  certificate and private key. The private key is encrypted before it is
  stored. For more information, see:

  [](https://cloud.google.com/compute/docs/load-balancing/http/ssl-certificates)
  """

  SSL_CERTIFICATE_ARG = None

  @classmethod
  def Args(cls, parser):
    parser.display_info.AddFormat(flags.DEFAULT_LIST_FORMAT)
    cls.SSL_CERTIFICATE_ARG = flags.SslCertificateArgument()
    cls.SSL_CERTIFICATE_ARG.AddArgument(parser, operation_type='create')

    parser.add_argument(
        '--description',
        help='An optional, textual description for the SSL certificate.')

    parser.add_argument(
        '--certificate',
        required=True,
        metavar='LOCAL_FILE_PATH',
        help="""\
        The path to a local certificate file. The certificate must be in PEM
        format.  The certificate chain must be no greater than 5 certs long. The
        chain must include at least one intermediate cert.
        """)

    parser.add_argument(
        '--private-key',
        required=True,
        metavar='LOCAL_FILE_PATH',
        help="""\
        The path to a local private key file. The private key must be in PEM
        format and must use RSA or ECDSA encryption.
        """)

    parser.display_info.AddCacheUpdater(flags.SslCertificatesCompleter)

  def Run(self, args):
    """Issues the request necessary for adding the SSL certificate."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    ssl_certificate_ref = self.SSL_CERTIFICATE_ARG.ResolveAsResource(
        args, holder.resources)
    certificate = file_utils.ReadFile(args.certificate, 'certificate')
    private_key = file_utils.ReadFile(args.private_key, 'private key')

    request = client.messages.ComputeSslCertificatesInsertRequest(
        sslCertificate=client.messages.SslCertificate(
            name=ssl_certificate_ref.Name(),
            certificate=certificate,
            privateKey=private_key,
            description=args.description),
        project=ssl_certificate_ref.project)

    return client.MakeRequests([(client.apitools_client.sslCertificates,
                                 'Insert', request)])


@base.UnicodeIsSupported
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class CreateAlpha(base.CreateCommand):
  """Create a Google Compute Engine SSL certificate.

  *{command}* is used to create SSL certificates which can be used to configure
  a target HTTPS proxy. An SSL certificate consists of a certificate and
  private key. The private key is encrypted before it is stored.

  You can create either a managed or a self-managed SslCertificate. Managed
  SslCertificate will be provisioned and renewed for you, when you specify
  --domains flag. Self-managed certificate is created by passing certificate
  obtained from Certificate Authority through --certificate and --private-key
  flags.
  """

  SSL_CERTIFICATE_ARG = None

  @classmethod
  def Args(cls, parser):
    parser.display_info.AddFormat(flags.ALPHA_LIST_FORMAT)
    cls.SSL_CERTIFICATE_ARG = flags.SslCertificateArgument()
    cls.SSL_CERTIFICATE_ARG.AddArgument(parser, operation_type='create')

    parser.add_argument(
        '--description',
        help='An optional, textual description for the SSL certificate.')

    managed_or_not = parser.add_group(
        mutex=True,
        required=True,
        help='Flags for managed or self-managed certificate. ')

    managed_or_not.add_argument(
        '--domains',
        metavar='DOMAIN',
        type=arg_parsers.ArgList(min_length=1),
        default=[],
        help="""\
        List of domains to create a managed certificate for.
        """)

    not_managed = managed_or_not.add_group('Flags for self-managed certificate')

    not_managed.add_argument(
        '--certificate',
        metavar='LOCAL_FILE_PATH',
        required=True,
        help="""\
        The path to a local certificate file to create a self-managed
        certificate. The certificate must be in PEM format. The certificate
        chain must be no greater than 5 certs long. The chain must include at
        least one intermediate cert.
        """)

    not_managed.add_argument(
        '--private-key',
        metavar='LOCAL_FILE_PATH',
        required=True,
        help="""\
        The path to a local private key file. The private key must be in PEM
        format and must use RSA or ECDSA encryption.
        """)

    parser.display_info.AddCacheUpdater(flags.SslCertificatesCompleter)

  def Run(self, args):
    """Issues the request necessary for adding the SSL certificate."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    ssl_certificate_ref = self.SSL_CERTIFICATE_ARG.ResolveAsResource(
        args, holder.resources)

    if args.certificate:
      certificate = file_utils.ReadFile(args.certificate, 'certificate')
      private_key = file_utils.ReadFile(args.private_key, 'private key')

      request = client.messages.ComputeSslCertificatesInsertRequest(
          sslCertificate=client.messages.SslCertificate(
              type=client.messages.SslCertificate.TypeValueValuesEnum.
              SELF_MANAGED,
              name=ssl_certificate_ref.Name(),
              selfManaged=client.messages.
              SslCertificateSelfManagedSslCertificate(
                  certificate=certificate,
                  privateKey=private_key,
              ),
              description=args.description),
          project=ssl_certificate_ref.project)

    if args.domains:
      request = client.messages.ComputeSslCertificatesInsertRequest(
          sslCertificate=client.messages.SslCertificate(
              type=client.messages.SslCertificate.TypeValueValuesEnum.MANAGED,
              name=ssl_certificate_ref.Name(),
              managed=client.messages.SslCertificateManagedSslCertificate(
                  domains=args.domains),
              description=args.description),
          project=ssl_certificate_ref.project)

    return client.MakeRequests([(client.apitools_client.sslCertificates,
                                 'Insert', request)])
