# Copyright 2018 Google Inc. All Rights Reserved.
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
"""Export image command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import daisy_utils
from googlecloudsdk.api_lib.compute import image_utils
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute.images import flags
from googlecloudsdk.core import properties

_DEFAULT_WORKFLOW = '../workflows/export/image_export.wf.json'
_EXTERNAL_WORKFLOW = '../workflows/export/image_export_ext.wf.json'


class Export(base.CreateCommand):
  """Export a Google Compute Engine image."""

  @staticmethod
  def Args(parser):
    image_group = parser.add_mutually_exclusive_group(required=True)

    image_group.add_argument(
        '--image',
        help=('The name of the disk image to export.'),
    )
    image_group.add_argument(
        '--image-family',
        help=('The family of the disk image to be exported. When a family '
              'is used instead of an image, the latest non-deprecated image '
              'associated with that family is used.'),
    )
    image_utils.AddImageProjectFlag(parser)

    parser.add_argument(
        '--destination-uri',
        required=True,
        help=('The Google Cloud Storage URI destination for '
              'the exported virtual disk file.'),
    )

    # Export format can take more values than what we list here in the help.
    # However, we don't want to suggest formats that will likely never be used,
    # so we list common ones here, but don't prevent others from being used.
    parser.add_argument(
        '--export-format',
        help=('Specify the format to export to, such as '
              '`vmdk`, `vhdx`, `vpc`, or `qcow2`.'),
    )
    daisy_utils.AddCommonDaisyArgs(parser)
    parser.display_info.AddCacheUpdater(flags.ImagesCompleter)

  def Run(self, args):
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client
    resources = holder.resources
    project = properties.VALUES.core.project.GetOrFail()

    image_expander = image_utils.ImageExpander(client, resources)
    image = image_expander.ExpandImageFlag(
        user_project=project,
        image=args.image,
        image_family=args.image_family,
        image_project=args.image_project,
        return_image_resource=False)
    image_ref = resources.Parse(image[0], collection='compute.images')

    variables = """source_image={0},destination={1}""".format(
        image_ref.RelativeName(), args.destination_uri)

    if args.export_format:
      workflow = _EXTERNAL_WORKFLOW
      variables += """,format={0}""".format(args.export_format.lower())
    else:
      workflow = _DEFAULT_WORKFLOW

    tags = ['gce-daisy-image-export']
    return daisy_utils.RunDaisyBuild(args, workflow, variables,
                                     tags=tags)

Export.detailed_help = {
    'brief': 'Export a Google Compute Engine image',
    'DESCRIPTION': """\
        *{command}* exports Virtual Disk images from Google Compute Engine.

        By default, images are exported in the Google Compute Engine format,
        which is a disk.raw file that has been tarred and gzipped.

        The `--export-format` flag will export the image to a format supported
        by QEMU using qemu-img. Valid formats include `vmdk`, `vhdx`, `vpc`,
        `vdi`, and `qcow2`.
        """,
}
