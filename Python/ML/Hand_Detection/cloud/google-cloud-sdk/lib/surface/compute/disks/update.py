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
"""Command for labels update to disks."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute.operations import poller
from googlecloudsdk.api_lib.util import waiter
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute.disks import flags as disks_flags
from googlecloudsdk.command_lib.util.args import labels_util


@base.ReleaseTracks(base.ReleaseTrack.GA)
class Update(base.UpdateCommand):
  r"""Update a Google Compute Engine persistent disk.

  *{command}* updates a Google Compute Engine persistent disk.
  For example:

    $ {command} example-disk --zone us-central1-a \
      --update-labels=k0=value1,k1=value2 --remove-labels=k3

  will add/update labels ``k0'' and ``k1'' and remove labels with key ``k3''.

  Labels can be used to identify the disk and to filter them as in

    $ {parent_command} list --filter='labels.k1:value2'

  To list existing labels

    $ {parent_command} describe example-disk --format='default(labels)'

  """

  DISK_ARG = None

  @classmethod
  def Args(cls, parser):
    cls.DISK_ARG = disks_flags.MakeDiskArg(plural=False)
    cls.DISK_ARG.AddArgument(parser, operation_type='update')
    labels_util.AddUpdateLabelsFlags(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client.apitools_client
    messages = holder.client.messages

    disk_ref = self.DISK_ARG.ResolveAsResource(
        args, holder.resources,
        scope_lister=flags.GetDefaultScopeLister(holder.client))

    labels_diff = labels_util.GetAndValidateOpsFromArgs(args)

    service = client.disks
    request_type = messages.ComputeDisksGetRequest

    disk = service.Get(request_type(**disk_ref.AsDict()))

    labels_update = labels_diff.Apply(messages.ZoneSetLabelsRequest.LabelsValue,
                                      disk.labels)

    if not labels_update.needs_update:
      return disk

    request = messages.ComputeDisksSetLabelsRequest(
        project=disk_ref.project,
        resource=disk_ref.disk,
        zone=disk_ref.zone,
        zoneSetLabelsRequest=messages.ZoneSetLabelsRequest(
            labelFingerprint=disk.labelFingerprint,
            labels=labels_update.labels))

    operation = service.SetLabels(request)
    operation_ref = holder.resources.Parse(
        operation.selfLink, collection='compute.zoneOperations')

    operation_poller = poller.Poller(service)
    return waiter.WaitFor(
        operation_poller, operation_ref,
        'Updating labels of disk [{0}]'.format(
            disk_ref.Name()))


@base.ReleaseTracks(base.ReleaseTrack.ALPHA, base.ReleaseTrack.BETA)
class UpdateAlphaBeta(base.UpdateCommand):
  r"""Update a Google Compute Engine persistent disk.

  *{command}* updates a Google Compute Engine persistent disk.
  For example:

    $ {command} example-disk --zone us-central1-a \
      --update-labels=k0=value1,k1=value2 --remove-labels=k3

  will add/update labels ``k0'' and ``k1'' and remove labels with key ``k3''.

  Labels can be used to identify the disk and to filter them as in

    $ {parent_command} list --filter='labels.k1:value2'

  To list existing labels

    $ {parent_command} describe example-disk --format='default(labels)'

  """
  DISK_ARG = None

  def GetLabelsReplacementRequest(
      self, disk_ref, disk, messages, labels_diff):
    if disk_ref.Collection() == 'compute.disks':
      labels_update = labels_diff.Apply(
          messages.ZoneSetLabelsRequest.LabelsValue, disk.labels)
      if labels_update.needs_update:
        return messages.ComputeDisksSetLabelsRequest(
            project=disk_ref.project,
            resource=disk_ref.disk,
            zone=disk_ref.zone,
            zoneSetLabelsRequest=messages.ZoneSetLabelsRequest(
                labelFingerprint=disk.labelFingerprint,
                labels=labels_update.labels))
    else:
      labels_update = labels_diff.Apply(
          messages.RegionSetLabelsRequest.LabelsValue, disk.labels)
      if labels_update.needs_update:
        return messages.ComputeRegionDisksSetLabelsRequest(
            project=disk_ref.project,
            resource=disk_ref.disk,
            region=disk_ref.region,
            regionSetLabelsRequest=messages.RegionSetLabelsRequest(
                labelFingerprint=disk.labelFingerprint,
                labels=labels_update.labels))
    return None

  def GetOperationCollection(self, disk_ref):
    if disk_ref.Collection() == 'compute.disks':
      return 'compute.zoneOperations'
    return 'compute.regionOperations'

  def GetDisksService(self, disk_ref, client):
    if disk_ref.Collection() == 'compute.disks':
      return client.disks
    return client.regionDisks

  def GetDiskGetRequest(self, disk_ref, messages):
    if disk_ref.Collection() == 'compute.disks':
      return messages.ComputeDisksGetRequest(**disk_ref.AsDict())
    return messages.ComputeRegionDisksGetRequest(**disk_ref.AsDict())

  @classmethod
  def Args(cls, parser):
    cls.DISK_ARG = disks_flags.MakeDiskArgZonalOrRegional(plural=False)
    cls.DISK_ARG.AddArgument(parser, operation_type='update')
    labels_util.AddUpdateLabelsFlags(parser)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client.apitools_client
    messages = holder.client.messages

    disk_ref = self.DISK_ARG.ResolveAsResource(
        args, holder.resources,
        scope_lister=flags.GetDefaultScopeLister(holder.client))
    labels_diff = labels_util.GetAndValidateOpsFromArgs(args)

    service = self.GetDisksService(disk_ref, client)
    disk = service.Get(self.GetDiskGetRequest(disk_ref, messages))

    set_labels_request = self.GetLabelsReplacementRequest(
        disk_ref, disk, messages, labels_diff)

    if not set_labels_request:
      return disk

    operation = service.SetLabels(set_labels_request)
    operation_ref = holder.resources.Parse(
        operation.selfLink, collection=self.GetOperationCollection(disk_ref))

    operation_poller = poller.Poller(service)
    return waiter.WaitFor(
        operation_poller, operation_ref,
        'Updating labels of disk [{0}]'.format(
            disk_ref.Name()))
