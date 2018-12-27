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
"""Import image command."""

from __future__ import absolute_import
from __future__ import unicode_literals
import os.path
import uuid

from googlecloudsdk.api_lib.compute import daisy_utils
from googlecloudsdk.api_lib.storage import storage_api
from googlecloudsdk.api_lib.storage import storage_util
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.command_lib.compute.images import flags
from googlecloudsdk.core import log
from googlecloudsdk.core import properties
from googlecloudsdk.core import resources
from googlecloudsdk.core.console import progress_tracker

_OS_CHOICES = {'debian-8': 'debian/translate_debian_8.wf.json',
               'debian-9': 'debian/translate_debian_9.wf.json',
               'centos-6': 'enterprise_linux/translate_centos_6.wf.json',
               'centos-7': 'enterprise_linux/translate_centos_7.wf.json',
               'rhel-6': 'enterprise_linux/translate_rhel_6_licensed.wf.json',
               'rhel-7': 'enterprise_linux/translate_centos_7_licensed.wf.json',
               'rhel-6-byol': 'enterprise_linux/translate_rhel_6_byol.wf.json',
               'rhel-7-byol': 'enterprise_linux/translate_rhel_7_byol.wf.json',
               'ubuntu-1404': 'ubuntu/translate_ubuntu_1404.wf.json',
               'ubuntu-1604': 'ubuntu/translate_ubuntu_1604.wf.json',
               'windows-2008r2': 'windows/translate_windows_2008_r2.wf.json',
               'windows-2012r2': 'windows/translate_windows_2012_r2.wf.json',
               'windows-2016': 'windows/translate_windows_2016.wf.json',
              }
_WORKFLOW_DIR = '../workflows/image_import/'
_IMPORT_WORKFLOW = _WORKFLOW_DIR + 'import_image.wf.json'
_IMPORT_FROM_IMAGE_WORKFLOW = _WORKFLOW_DIR + 'import_from_image.wf.json'
_IMPORT_AND_TRANSLATE_WORKFLOW = _WORKFLOW_DIR + 'import_and_translate.wf.json'
_WORKFLOWS_URL = ('https://github.com/GoogleCloudPlatform/compute-image-tools/'
                  'tree/master/daisy_workflows/image_import')


def _IsLocalFile(file_name):
  return not (file_name.startswith('gs://') or
              file_name.startswith('https://'))


def _UploadToGcs(is_async, local_path, daisy_bucket, image_uuid):
  """Uploads a local file to GCS. Returns the gs:// URI to that file."""
  file_name = os.path.basename(local_path).replace(' ', '-')
  dest_path = 'gs://{0}/tmpimage/{1}-{2}'.format(
      daisy_bucket, image_uuid, file_name)
  if is_async:
    log.status.Print('Async: Once upload is complete, your image will be '
                     'imported from Cloud Storage asynchronously.')
  with progress_tracker.ProgressTracker(
      'Copying [{0}] to [{1}]'.format(local_path, dest_path)):
    retcode = storage_util.RunGsutilCommand('cp', [local_path, dest_path])
  if retcode != 0:
    log.err.Print('Failed to upload file. See {} for details.'.format(
        log.GetLogFilePath()))
    raise exceptions.FailedSubCommand(
        ['gsutil', 'cp', local_path, dest_path], retcode)
  return dest_path


def _CopyToScratchBucket(source_uri, image_uuid, storage_client, daisy_bucket):
  """Copy image from source_uri to daisy scratch bucket."""
  image_file = os.path.basename(source_uri)
  dest_uri = 'gs://{0}/tmpimage/{1}-{2}'.format(
      daisy_bucket, image_uuid, image_file)
  src_object = resources.REGISTRY.Parse(source_uri,
                                        collection='storage.objects')
  dest_object = resources.REGISTRY.Parse(dest_uri,
                                         collection='storage.objects')
  with progress_tracker.ProgressTracker(
      'Copying [{0}] to [{1}]'.format(source_uri, dest_uri)):
    storage_client.Rewrite(src_object, dest_object)
  return dest_uri


def _GetTranslateWorkflow(args):
  if args.os:
    return _OS_CHOICES[args.os]
  return args.custom_workflow


def _MakeGcsUri(uri):
  obj_ref = resources.REGISTRY.Parse(uri)
  return 'gs://{0}/{1}'.format(obj_ref.bucket, obj_ref.object)


class Import(base.CreateCommand):
  """Import a Google Compute Engine image."""

  @staticmethod
  def Args(parser):
    Import.DISK_IMAGE_ARG = flags.MakeDiskImageArg()
    Import.DISK_IMAGE_ARG.AddArgument(parser, operation_type='create')

    flags.compute_flags.AddZoneFlag(
        parser, 'image', 'import',
        explanation='The zone in which to do the work of importing the image.')

    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        '--source-file',
        help=("""A local file, or the Google Cloud Storage URI of the virtual
              disk file to import. For example: ``gs://my-bucket/my-image.vmdk''
              or ``./my-local-image.vmdk''"""),
    )
    flags.SOURCE_IMAGE_ARG.AddArgument(source, operation_type='import')

    workflow = parser.add_mutually_exclusive_group(required=True)
    workflow.add_argument(
        '--os',
        choices=sorted(_OS_CHOICES.keys()),
        help='Specifies the OS of the image being imported.'
    )
    workflow.add_argument(
        '--data-disk',
        help=('Specifies that the disk has no bootable OS installed on it. '
              'Imports the disk without making it bootable or installing '
              'Google tools on it.'),
        action='store_true'
    )
    workflow.add_argument(
        '--custom-workflow',
        help=("""\
              Specifies a custom workflow to use for image translation.
              Workflow should be relative to the image_import directory here:
              []({0}). For example: ``{1}''""".format(
                  _WORKFLOWS_URL, _OS_CHOICES[sorted(_OS_CHOICES.keys())[0]])),
        hidden=True
    )

    daisy_utils.AddCommonDaisyArgs(parser)
    parser.display_info.AddCacheUpdater(flags.ImagesCompleter)

  def Run(self, args):
    storage_client = storage_api.StorageClient()
    daisy_bucket = daisy_utils.GetAndCreateDaisyBucket(
        storage_client=storage_client)
    image_uuid = uuid.uuid4()

    daisy_vars = ['image_name={}'.format(args.image_name)]
    if args.source_image:
      # If we're starting from an image, then we've already imported it.
      workflow = _IMPORT_FROM_IMAGE_WORKFLOW
      daisy_vars.append(
          'translate_workflow={}'.format(_GetTranslateWorkflow(args)))
      ref = resources.REGISTRY.Parse(
          args.source_image,
          collection='compute.images',
          params={'project': properties.VALUES.core.project.GetOrFail})
      # source_name should be of the form 'global/images/image-name'.
      source_name = ref.RelativeName()[len(ref.Parent().RelativeName() + '/'):]
      daisy_vars.append('source_image={}'.format(source_name))
    else:
      # If the file is an OVA file, print a warning.
      if args.source_file.endswith('.ova'):
        log.warning('The specified input file may contain more than one '
                    'virtual disk. Only the first vmdk disk will be '
                    'imported. ')
      elif (args.source_file.endswith('.tar.gz')
            or args.source_file.endswith('.tgz')):
        raise exceptions.BadFileException(
            '"gcloud compute images import" does not support compressed '
            'archives. Please extract your image and try again.\n If you got '
            'this file by exporting an image from Compute Engine (e.g. by '
            'using "gcloud compute images export") then you can instead use '
            '"gcloud compute images create" to create your image from your '
            '.tar.gz file.')

      # Get the image into the scratch bucket, wherever it is now.
      if _IsLocalFile(args.source_file):
        gcs_uri = _UploadToGcs(args.async, args.source_file,
                               daisy_bucket, image_uuid)
      else:
        source_file = _MakeGcsUri(args.source_file)
        gcs_uri = _CopyToScratchBucket(source_file, image_uuid,
                                       storage_client, daisy_bucket)

      # Import and (maybe) translate from the scratch bucket.
      daisy_vars.append('source_disk_file={}'.format(gcs_uri))
      if args.data_disk:
        workflow = _IMPORT_WORKFLOW
      else:
        workflow = _IMPORT_AND_TRANSLATE_WORKFLOW
        daisy_vars.append(
            'translate_workflow={}'.format(_GetTranslateWorkflow(args)))

    # TODO(b/79591894): Once we've cleaned up the Argo output, replace this
    # warning message with a ProgressTracker spinner.
    log.warning('Importing image. This may take up to 2 hours.')
    return daisy_utils.RunDaisyBuild(args, workflow, ','.join(daisy_vars),
                                     daisy_bucket=daisy_bucket,
                                     user_zone=args.zone)

Import.detailed_help = {
    'brief': 'Import a Google Compute Engine image',
    'DESCRIPTION': """\
        *{command}* imports Virtual Disk images, such as VMWare VMDK files
        and VHD files, into Google Compute Engine.

        Importing images involves 3 steps:
        *  Upload the virtual disk file to Google Cloud Storage.
        *  Import the image to Google Compute Engine.
        *  Translate the image to make a bootable image.
        This command will perform all three of these steps as necessary,
        depending on the input arguments specified by the user.

        This command uses the `--os` flag to choose the appropriate translation.
        You can omit the translation step using the `--data-disk` flag.
        """,
}
