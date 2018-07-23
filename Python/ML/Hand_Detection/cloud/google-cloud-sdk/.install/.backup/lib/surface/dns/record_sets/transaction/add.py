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

"""gcloud dns record-sets transaction add command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.dns import transaction_util as trans_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.dns import flags
from googlecloudsdk.core import log


class Add(base.Command):
  r"""Append a record-set addition to the transaction.

  This command appends a record-set addition to the transaction.

  ## EXAMPLES

  To add an A record, run:

    $ {command} --zone MANAGED_ZONE --name my.domain. --ttl 1234 \
        --type A "1.2.3.4"

  To add a TXT record with multiple data values, run:

    $ {command} --zone MANAGED_ZONE --name my.domain. --ttl 2345 \
        --type TXT "Hello world" "Bye world"
  """

  @staticmethod
  def Args(parser):
    flags.GetZoneArg().AddToParser(parser)
    parser.add_argument(
        '--name', required=True,
        help='DNS name of the record-set to add.')
    parser.add_argument(
        '--ttl', required=True, type=int,
        help='TTL for the record-set to add.')
    parser.add_argument(
        '--type', required=True,
        help='Type of the record-set to add.')
    parser.add_argument(
        'data', nargs='+',
        help='DNS data (Address/CNAME/MX info, etc.) of the record-set to add.')

  def Run(self, args):
    api_version = 'v1'
    # If in the future there are differences between API version, do NOT use
    # this patter of checking ReleaseTrack. Break this into multiple classes.
    if self.ReleaseTrack() == base.ReleaseTrack.BETA:
      api_version = 'v1beta2'

    with trans_util.TransactionFile(args.transaction_file) as trans_file:
      change = trans_util.ChangeFromYamlFile(
          trans_file, api_version=api_version)

    change.additions.append(
        trans_util.CreateRecordSetFromArgs(args, api_version=api_version))

    with trans_util.TransactionFile(args.transaction_file, 'w') as trans_file:
      trans_util.WriteToYamlFile(trans_file, change)

    log.status.Print(
        'Record addition appended to transaction at [{0}].'.format(
            args.transaction_file))
