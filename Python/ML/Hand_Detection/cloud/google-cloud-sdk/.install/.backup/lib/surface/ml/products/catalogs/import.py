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

"""gcloud ml products catalogs import command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.ml.products import flags


class Import(base.CreateCommand):
  """Import a Cloud Product Search Catalog.

  This command imports a Cloud Product Search Catalog from a CSV file URI.

  URI should point to a CSV file in Google Cloud Storage bucket
  and start with: `gs://`

  The file itself must contain one ReferenceImage record per row with the
  following format:

  * catalog_name - The catalog ID to be created.
  * image_uri    - The Google Cloud Storage location of the image.
                   The URI must start with gs://.
  * product_id   - A user-defined ID for the product identified by
                  the reference image. A product ID can be associated with
                  multiple reference images. Restricted to 255 characters
                  including letters, numbers, underscore ( _ ) and hyphen (-).
  * product_category - String specifing the product category for the image.
  * bounding_poly    - A set of vertices defining the bounding polygon around
                      the area of interest in the image. Should be a list of an
                      even number of integers separated by commas
                      (e.g. "p1_x,p1_y,p2_x,p2_y,...,pn_x,pn_y") specifying,
                      the vertices in clockwise order. Defaults to full image
                      if empty.

  ## EXAMPLES

  To import a product search catalog, run:

    $ {command} gs://my-bucket/my-catalog.csv

  """

  @staticmethod
  def Args(parser):
    flags.AddCatalogImportSourceArg(parser)
    parser.display_info.AddFormat('json')

  def Run(self, args):
    api_client = product_util.ProductsClient()
    import_response = api_client.ImportCatalog(args.source)
    return import_response
