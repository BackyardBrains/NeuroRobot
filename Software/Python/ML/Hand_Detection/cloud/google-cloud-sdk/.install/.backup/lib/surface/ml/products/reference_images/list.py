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

"""gcloud ml products reference-images list command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.ml.products import flags
from googlecloudsdk.command_lib.ml.products import util as products_command_util


class List(base.ListCommand):
  """List all Cloud Product Search ReferenceImages.

  This command lists all Cloud Product Search ReferenceImages within a catalog.

  ## EXAMPLES

  To list all product search reference images for a catalog, run:

    $ {command} --catalog-id=101

  To list all product search reference images for a specific product in
  a catalog, run:

    $ {command} --catalog-id=101 --product-id=my-product

  {alpha_list_note}
  """

  detailed_help = {'alpha_list_note': products_command_util.ALPHA_LIST_NOTE}

  @staticmethod
  def Args(parser):
    list_verb = 'to list reference images for'
    flags.AddCatalogResourceArg(parser, verb=list_verb, positional=False)
    flags.AddProductIdFlag(parser, verb=list_verb)
    parser.display_info.AddFormat(products_command_util.REF_IMAGE_LIST_FORMAT)

  def Run(self, args):
    catalog_ref = args.CONCEPTS.catalog.Parse()

    api_client = product_util.ProductsClient()
    return api_client.ListRefImages(catalog_ref.RelativeName(),
                                    args.product_id,
                                    args.page_size if args.page_size else 10,
                                    args.limit)

