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

"""gcloud ml products reference-images describe command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.ml.products import flags


class Describe(base.DescribeCommand):
  """Describe a Cloud Product Search ReferenceImage.

  This command describes a Cloud Product Search ReferenceImage.
  """

  @staticmethod
  def Args(parser):
    flags.AddReferenceImageResourceArg(parser, verb='to describe')
    parser.display_info.AddFormat('json')

  def Run(self, args):
    api_client = product_util.ProductsClient()
    image_ref = args.CONCEPTS.reference_image.Parse()
    return api_client.DescribeRefImage(image_ref.RelativeName())
