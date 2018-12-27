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

"""Command for changing the default service of a URL map."""

from __future__ import absolute_import
from __future__ import unicode_literals
from apitools.base.py import encoding

from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.backend_buckets import (
    flags as backend_bucket_flags)
from googlecloudsdk.command_lib.compute.backend_services import (
    flags as backend_service_flags)
from googlecloudsdk.command_lib.compute.url_maps import flags
from googlecloudsdk.core import log


class SetDefaultService(base.UpdateCommand):
  """Change the default service or default bucket of a URL map.

  *{command}* is used to change the default service or default
  bucket of a URL map. The default service or default bucket is
  used for any requests for which there is no mapping in the
  URL map.
  """

  BACKEND_BUCKET_ARG = None
  BACKEND_SERVICE_ARG = None
  URL_MAP_ARG = None

  @classmethod
  def Args(cls, parser):
    cls.BACKEND_BUCKET_ARG = (
        backend_bucket_flags.BackendBucketArgumentForUrlMap(required=False))
    cls.BACKEND_SERVICE_ARG = (
        backend_service_flags.BackendServiceArgumentForUrlMap(required=False))
    cls.URL_MAP_ARG = flags.UrlMapArgument()
    cls.URL_MAP_ARG.AddArgument(parser)

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--default-service',
        help=('A backend service that will be used for requests for which this '
              'URL map has no mappings.'))
    group.add_argument(
        '--default-backend-bucket',
        help=('A backend bucket that will be used for requests for which this '
              'URL map has no mappings.'))

  def GetGetRequest(self, client, url_map_ref):
    """Returns the request for the existing URL map resource."""
    return (client.apitools_client.urlMaps,
            'Get',
            client.messages.ComputeUrlMapsGetRequest(
                urlMap=url_map_ref.Name(),
                project=url_map_ref.project))

  def GetSetRequest(self, client, url_map_ref, replacement):
    return (client.apitools_client.urlMaps,
            'Update',
            client.messages.ComputeUrlMapsUpdateRequest(
                urlMap=url_map_ref.Name(),
                urlMapResource=replacement,
                project=url_map_ref.project))

  def Modify(self, resources, args, existing):
    """Returns a modified URL map message."""
    replacement = encoding.CopyProtoMessage(existing)

    if args.default_service:
      default_backend_uri = self.BACKEND_SERVICE_ARG.ResolveAsResource(
          args, resources).SelfLink()
    else:
      default_backend_uri = self.BACKEND_BUCKET_ARG.ResolveAsResource(
          args, resources).SelfLink()

    replacement.defaultService = default_backend_uri

    return replacement

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    url_map_ref = self.URL_MAP_ARG.ResolveAsResource(args, holder.resources)
    get_request = self.GetGetRequest(client, url_map_ref)

    objects = client.MakeRequests([get_request])

    new_object = self.Modify(holder.resources, args, objects[0])

    # If existing object is equal to the proposed object or if
    # Modify() returns None, then there is no work to be done, so we
    # print the resource and return.
    if objects[0] == new_object:
      log.status.Print(
          'No change requested; skipping update for [{0}].'.format(
              objects[0].name))
      return objects

    return client.MakeRequests(
        [self.GetSetRequest(client, url_map_ref, new_object)])
