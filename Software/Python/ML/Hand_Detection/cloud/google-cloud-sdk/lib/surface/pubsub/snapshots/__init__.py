# Copyright 2016 Google Inc. All Rights Reserved.
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

"""The main command group for Cloud Pub/Sub snapshots."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.calliope import base


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class Snapshots(base.Group):
  """These features are part of an invite-only release of the Cloud Pub/Sub API.

  Manage Cloud Pub/Sub snapshots.
  These features are part of an invitation-only release of the underlying
  Cloud Pub/Sub API. These commands will generate errors unless you have access
  to this API. This restriction should be relaxed in the near future. Please
  contact cloud-pubsub@google.com with any questions in the meantime.
  """
  pass
