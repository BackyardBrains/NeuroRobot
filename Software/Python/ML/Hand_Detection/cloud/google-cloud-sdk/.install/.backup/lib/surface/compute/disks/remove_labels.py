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
"""Command for removing labels from disks."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute.operations import poller
from googlecloudsdk.api_lib.util import waiter
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute import labels_doc_helper
from googlecloudsdk.command_lib.compute import labels_flags
from googlecloudsdk.command_lib.compute.disks import flags as disks_flags
from googlecloudsdk.command_lib.util.args import labels_util


@base.ReleaseTracks(base.ReleaseTrack.ALPHA, base.ReleaseTrack.BETA,
                    base.ReleaseTrack.GA)
class RemoveLabels(base.UpdateCommand):
  """remove-labels command for disks."""

  DISK_ARG = None

  @classmethod
  def Args(cls, parser):
    # Regional disk is in Alpha and Beta only.
    if cls.ReleaseTrack() == base.ReleaseTrack.GA:
      cls.DISK_ARG = disks_flags.MakeDiskArg(plural=False)
    else:
      cls.DISK_ARG = disks_flags.MakeDiskArgZonalOrRegional(plural=False)
    cls.DISK_ARG.AddArgument(parser)
    labels_flags.AddArgsForRemoveLabels(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client.apitools_client
    messages = holder.client.messages

    disk_ref = self.DISK_ARG.ResolveAsResource(
        args, holder.resources,
        scope_lister=flags.GetDefaultScopeLister(holder.client))

    remove_labels = labels_util.GetUpdateLabelsDictFromArgs(args)

    if disk_ref.Collection() == 'compute.disks':
      service = client.disks
      request_type = messages.ComputeDisksGetRequest
    elif disk_ref.Collection() == 'compute.regionDisks':
      service = client.regionDisks
      request_type = messages.ComputeRegionDisksGetRequest
    else:
      raise ValueError('Unexpected resource argument of {}'
                       .format(disk_ref.Collection()))

    disk = service.Get(request_type(**disk_ref.AsDict()))

    if args.all:
      # removing all existing labels from the disk.
      remove_labels = {}
      if disk.labels:
        for label in disk.labels.additionalProperties:
          remove_labels[label.key] = label.value

    labels_diff = labels_util.Diff(subtractions=remove_labels)
    if disk_ref.Collection() == 'compute.disks':
      operation_collection = 'compute.zoneOperations'
      labels_update = labels_diff.Apply(
          messages.ZoneSetLabelsRequest.LabelsValue, disk.labels)
      request = messages.ComputeDisksSetLabelsRequest(
          project=disk_ref.project,
          resource=disk_ref.disk,
          zone=disk_ref.zone,
          zoneSetLabelsRequest=messages.ZoneSetLabelsRequest(
              labelFingerprint=disk.labelFingerprint,
              labels=labels_update.GetOrNone()))
    else:
      operation_collection = 'compute.regionOperations'
      labels_update = labels_diff.Apply(
          messages.RegionSetLabelsRequest.LabelsValue, disk.labels)
      request = messages.ComputeRegionDisksSetLabelsRequest(
          project=disk_ref.project,
          resource=disk_ref.disk,
          region=disk_ref.region,
          regionSetLabelsRequest=messages.RegionSetLabelsRequest(
              labelFingerprint=disk.labelFingerprint,
              labels=labels_update.GetOrNone()))

    if not labels_update.needs_update:
      return disk

    operation = service.SetLabels(request)
    operation_ref = holder.resources.Parse(
        operation.selfLink, collection=operation_collection)

    operation_poller = poller.Poller(service)
    return waiter.WaitFor(
        operation_poller, operation_ref,
        'Updating labels of disk [{0}]'.format(
            disk_ref.Name()))


RemoveLabels.detailed_help = (
    labels_doc_helper.GenerateDetailedHelpForRemoveLabels('disk'))
