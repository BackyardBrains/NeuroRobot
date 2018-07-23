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

"""gcloud ml products reference-image create command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import parser_errors
from googlecloudsdk.command_lib.ml.products import flags
from googlecloudsdk.command_lib.ml.products import util as products_command_util
from googlecloudsdk.core import log


class Add(base.CreateCommand):
  r"""Add a Cloud Product Search ReferenceImage to a Catalog.

  This command creates a Cloud Product Search ReferenceImage and adds it to the
  provided catalog.

  ## EXAMPLES

  To create a reference image, using default bounds and no category, run:

    $ {command} \
    gs:\\my-bucket\myimage.jpg
    --catalog=101
    --product-id=my-product-123

  To add a reference image, using custom bounds and category, run:

    $ {command} \
    gs:\\my-bucket\myimage.jpg
    --catalog=101
    --product-id=my-product-123
    --category=mens_shoes
    --bounds=200:200,200:400,400:200,400:400


  {alpha_list_note}
  """

  detailed_help = {'alpha_list_note': products_command_util.ALPHA_LIST_NOTE}

  @staticmethod
  def Args(parser):
    flags.AddReferenceImageCreateFlags(parser)

  def Run(self, args):
    catalog_ref = args.CONCEPTS.catalog.Parse()
    api_client = product_util.ProductsClient()

    # TODO(b/69863480) Remove this once optional modal groups are fixed
    if (args.bounds or args.category) and not (args.bounds and args.category):
      missing = 'bounds' if not args.bounds else 'category'
      raise parser_errors.ArgumentError(
          'Missing [{}]. Both category and bounds must be specified if '
          'either is provided'.format(missing))
    ref_image = api_client.BuildRefImage(
        args.product_id,
        args.image_path,
        bounds=api_client.BuildBoundingPoly(args.bounds),
        product_category=args.category)
    created_image = api_client.CreateRefImage(ref_image,
                                              catalog_ref.RelativeName())
    log.CreatedResource(created_image.name, kind='ReferenceImage')
    return created_image
