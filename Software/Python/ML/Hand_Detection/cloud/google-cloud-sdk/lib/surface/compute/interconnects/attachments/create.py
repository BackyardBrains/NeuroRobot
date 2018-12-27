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
"""Command for creating interconnects."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute.interconnects.attachments import client
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import parser_errors
from googlecloudsdk.command_lib.compute import flags as compute_flags
from googlecloudsdk.command_lib.compute.interconnects import flags as interconnect_flags
from googlecloudsdk.command_lib.compute.interconnects.attachments import flags as attachment_flags
from googlecloudsdk.command_lib.compute.routers import flags as router_flags

_DEPRECATION_WARNING = """\
    `create` is deprecated. Please use `gcloud compute interconnects attachments dedicated create` instead.
    """

_DEPRECATION_ERROR = """\
    `create` has been removed. Please use `gcloud compute interconnects attachments dedicated create` instead.
    """


# TODO(b/79153388): Clean up this command flag after 3 months of deprecation.
@base.Deprecate(
    is_removed=False, warning=_DEPRECATION_WARNING, error=_DEPRECATION_ERROR)
class Create(base.CreateCommand):
  """Create a Google Compute Engine interconnect attachment.

  *{command}* is used to create interconnect attachments. An interconnect
  attachment is what binds the underlying connectivity of an Interconnect to a
  path into and out of the customer's cloud network.
  """
  INTERCONNECT_ATTACHMENT_ARG = None
  INTERCONNECT_ARG = None
  ROUTER_ARG = None

  @classmethod
  def Args(cls, parser):

    cls.INTERCONNECT_ARG = (
        interconnect_flags.InterconnectArgumentForOtherResource(
            'The interconnect for the interconnect attachment'))
    cls.INTERCONNECT_ARG.AddArgument(parser)

    cls.ROUTER_ARG = router_flags.RouterArgumentForOtherResources()
    cls.ROUTER_ARG.AddArgument(parser)

    cls.INTERCONNECT_ATTACHMENT_ARG = (
        attachment_flags.InterconnectAttachmentArgument())
    cls.INTERCONNECT_ATTACHMENT_ARG.AddArgument(parser, operation_type='create')

    parser.add_argument(
        '--description',
        help='An optional, textual description for the '
        'interconnect attachment.')

    parser.display_info.AddCacheUpdater(
        interconnect_flags.InterconnectsCompleter)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    attachment_ref = self.INTERCONNECT_ATTACHMENT_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=compute_flags.GetDefaultScopeLister(holder.client))

    interconnect_attachment = client.InterconnectAttachment(
        attachment_ref, compute_client=holder.client)

    interconnect_ref = None
    if args.interconnect is not None:
      interconnect_ref = self.INTERCONNECT_ARG.ResolveAsResource(
          args, holder.resources)

    if args.router_region is None:
      args.router_region = attachment_ref.region

    if args.router_region != attachment_ref.region:
      raise parser_errors.ArgumentException(
          'router-region must be same as the attachment region.')

    router_ref = None
    if args.router is not None:
      router_ref = self.ROUTER_ARG.ResolveAsResource(args, holder.resources)

    return interconnect_attachment.Create(
        description=args.description,
        interconnect=interconnect_ref,
        router=router_ref)
