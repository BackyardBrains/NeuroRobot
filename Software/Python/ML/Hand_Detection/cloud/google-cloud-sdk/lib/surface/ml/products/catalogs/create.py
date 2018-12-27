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

"""gcloud ml products catalogs create command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.ml.products import util as products_command_util
from googlecloudsdk.core import log


class Create(base.CreateCommand):
  """Create a Cloud Product Search Catalog to contain ReferenceImages.

  This command creates a Cloud Product Search Catalog.

  ## EXAMPLES

  To create a product search catalog, run:

    $ {command}


  {alpha_list_note}
  """

  detailed_help = {'alpha_list_note': products_command_util.ALPHA_LIST_NOTE}

  def Run(self, args):
    api_client = product_util.ProductsClient()
    catalog = api_client.CreateCatalog()
    log.CreatedResource(catalog.name, kind='Catalog')
    return catalog
