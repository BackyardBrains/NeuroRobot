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
from googlecloudsdk.calliope import base
from surface.compute.interconnects import update


DEPRECATED_WARNING_MESSAGE = """\
This command is deprecated. Please use `gcloud{}compute interconnects update`
instead."""


@base.Deprecate(is_removed=False)
@base.ReleaseTracks(base.ReleaseTrack.GA)
class Patch(update.Update):
  """Patch a Google Compute Engine interconnect.

  *{command}* is used to patch interconnects. An interconnect represents a
  single specific connection between Google and the customer.
  """


@base.Deprecate(warning=DEPRECATED_WARNING_MESSAGE.format(' beta '),
                is_removed=False)
@base.ReleaseTracks(base.ReleaseTrack.BETA)
class PatchBeta(update.UpdateLabels):
  """Update a Google Compute Engine interconnect.

  *{command}* is used to update interconnects. An interconnect represents a
  single specific connection between Google and the customer.
  """


@base.Deprecate(warning=DEPRECATED_WARNING_MESSAGE.format(' alpha '),
                is_removed=True)
@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class PatchAlpha(update.UpdateLabels):
  """Update a Google Compute Engine interconnect."""
