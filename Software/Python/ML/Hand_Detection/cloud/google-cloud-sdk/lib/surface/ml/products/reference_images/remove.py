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

"""gcloud ml products reference-images remove command."""

from __future__ import absolute_import
from __future__ import unicode_literals

from googlecloudsdk.api_lib.ml.products import product_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.ml.products import flags
from googlecloudsdk.command_lib.ml.products import util as products_command_util
from googlecloudsdk.core import log
from googlecloudsdk.core.console import console_io


class Remove(base.DeleteCommand):
  """Remove a Cloud Product Search ReferenceImage.

  This command removes a Cloud Product Search ReferenceImage.

  {delete_image_note}

  """
  detailed_help = {'delete_image_note': products_command_util.DELETE_IMAGE_NOTE}

  @staticmethod
  def Args(parser):
    flags.AddReferenceImageResourceArg(parser, verb='to remove')

  def Run(self, args):
    image_ref = args.CONCEPTS.reference_image.Parse()
    console_io.PromptContinue(
        'ReferenceImage [{}] will be removed.'.format(image_ref.Name()),
        cancel_on_no=True)
    api_client = product_util.ProductsClient()
    result = api_client.DeleteRefImage(image_ref.RelativeName())
    log.DeletedResource(image_ref.Name(), kind='ReferenceImage')
    return result
