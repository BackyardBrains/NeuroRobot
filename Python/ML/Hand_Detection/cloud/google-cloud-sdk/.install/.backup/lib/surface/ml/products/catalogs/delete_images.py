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

"""gcloud ml products catalogs delete-images command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.ml.products import flags
from googlecloudsdk.command_lib.ml.products import util as products_command_util
from googlecloudsdk.core import log
from googlecloudsdk.core.console import console_io


class DeleteImages(base.DeleteCommand):
  """Delete ReferenceImages from a Cloud Product Search Catalog.

  This command deletes all ReferenceImages for a given product id from a
  Cloud Product Search Catalog.

  {delete_image_note}

  ## EXAMPLES

  To delete all images for product abc123 from a catalog, run:

    $ {command} CATALOG --product-id abc123
  """

  detailed_help = {'delete_image_note': products_command_util.DELETE_IMAGE_NOTE}

  @staticmethod
  def Args(parser):
    flags.AddCatalogResourceArg(parser, verb='to delete')
    flags.AddProductIdFlag(parser, verb='to delete ReferenceImages for',
                           required=True)

  def Run(self, args):
    catalog_ref = args.CONCEPTS.catalog.Parse()
    console_io.PromptContinue(
        'All images for product id [{}] will be deleted from catalog [{}].'.
        format(args.product_id, catalog_ref.Name()),
        cancel_on_no=True)
    api_client = product_util.ProductsClient()
    result = api_client.DeleteProductCatalogImages(catalog_ref.RelativeName(),
                                                   args.product_id)
    log.status.Print('Deleted ReferenceImages for Catalog [{}] '
                     'with product id [{}].'.format(catalog_ref.Name(),
                                                    args.product_id))
    return result
