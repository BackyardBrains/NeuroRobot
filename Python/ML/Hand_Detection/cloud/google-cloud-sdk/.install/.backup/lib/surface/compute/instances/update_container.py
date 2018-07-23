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
"""Command for creating VM instances running Docker images."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.api_lib.compute import containers_utils
from googlecloudsdk.api_lib.compute.operations import poller
from googlecloudsdk.api_lib.util import waiter
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.command_lib.compute.instances import flags as instances_flags


@base.ReleaseTracks(base.ReleaseTrack.ALPHA, base.ReleaseTrack.BETA)
class UpdateContainer(base.UpdateCommand):
  """Command for updating VM instances running container images."""

  @staticmethod
  def Args(parser):
    """Register parser args."""
    instances_flags.INSTANCE_ARG.AddArgument(parser, operation_type='update')

    def NonEmpty(parameter_name):
      def Factory(string):
        if not string:
          raise exceptions.InvalidArgumentException(
              parameter_name, 'Empty string is not allowed.')
        return string
      return Factory

    parser.add_argument(
        '--container-image',
        type=NonEmpty('--container-image'),
        help="""\
        Sets container image in the declaration to the specified value.

        Empty string is not allowed.
        """)

    command_group = parser.add_mutually_exclusive_group()

    command_group.add_argument(
        '--container-command',
        type=NonEmpty('--container-command'),
        help="""\
        Sets command in the declaration to the specified value.
        Empty string is not allowed.

        Cannot be used in the same command with `--clear-container-command`.
        """)

    command_group.add_argument(
        '--clear-container-command',
        action='store_true',
        default=None,
        help="""\
        Removes command from container declaration.

        Cannot be used in the same command with `--container-command`.
        """)

    arg_group = parser.add_mutually_exclusive_group()

    arg_group.add_argument(
        '--container-arg',
        action='append',
        help="""\
        Completely replaces the list of arguments with the new list.
        Each argument must have a separate --container-arg flag.
        Arguments are appended the new list in the order of flags.

        Cannot be used in the same command with `--clear-container-arg`.
        """)

    arg_group.add_argument(
        '--clear-container-args',
        action='store_true',
        default=None,
        help="""\
        Removes the list of arguments from container declaration.

        Cannot be used in the same command with `--container-arg`.
        """
    )

    parser.add_argument(
        '--container-privileged',
        action='store_true',
        default=None,
        help="""\
        Sets permission to run container to the specified value.
        """)

    def ParseMountVolumeMode(mode):
      if not mode or mode == 'rw':
        return containers_utils.MountVolumeMode.READ_WRITE
      elif mode == 'ro':
        return containers_utils.MountVolumeMode.READ_ONLY
      else:
        raise exceptions.InvalidArgumentException(
            '--run-mount-volume', 'Mode can only be "ro" or "rw".')

    mount_group = parser.add_argument_group()

    mount_group.add_argument(
        '--container-mount-host-path',
        metavar='host-path=HOSTPATH,mount-path=MOUNTPATH[,mode=MODE]',
        type=arg_parsers.ArgDict(spec={'host-path': str,
                                       'mount-path': str,
                                       'mode': ParseMountVolumeMode}),
        action='append',
        help="""\
        Mounts a volume by using `host-path`.
        - Adds a volume, if `mount-path` is not yet declared.
        - Replaces a volume, if `mount-path` is declared.
        All parameters (`host-path`, `mount-path`, `mode`) are completely
        replaced.

        *host-path*::: Path on host to mount from.

        *mount-path*::: Path on container to mount to.

        *mode*::: Volume mount mode: rw (read/write) or ro (read-only).

        Default: rw.
        """)

    mount_group.add_argument(
        '--container-mount-tmpfs',
        metavar='mount-path=MOUNTPATH',
        type=arg_parsers.ArgDict(spec={'mount-path': str}),
        action='append',
        help="""\
        Mounts empty tmpfs into container at MOUNTPATH.

        *mount-path*::: Path on container to mount to.
        """)

    mount_group.add_argument(
        '--remove-container-mounts',
        type=arg_parsers.ArgList(),
        metavar='MOUNTPATH[,MOUNTPATH,...]',
        help="""\
        Removes volume mounts (`host-path`, `tmpfs`) with `mountPath: MOUNTPATH`
        from container declaration.

        Does nothing, if a volume mount is not declared.
        """
    )

    env_group = parser.add_argument_group()

    env_group.add_argument(
        '--container-env',
        type=arg_parsers.ArgDict(),
        action='append',
        metavar='KEY=VALUE, ...',
        help="""\
        Update environment variables `KEY` with value `VALUE` passed to
        container.
        - Sets `KEY` to the specified value.
        - Adds `KEY` = `VALUE`, if `KEY` is not yet declared.
        - Only the last value of `KEY` is taken when `KEY` is repeated more
        than once.

        Values, declared with `--container-env` flag override those with the
        same `KEY` from file, provided in `--container-env-file`.
        """)

    env_group.add_argument(
        '--container-env-file',
        help="""\
        Update environment variables from a file.
        Same update rules as for `--container-env` apply.
        Values, declared with `--container-env` flag override those with the
        same `KEY` from file.

        File with environment variables declarations in format used by docker
        (almost). This means:
        - Lines are in format KEY=VALUE
        - Values must contain equality signs.
        - Variables without values are not supported (this is different from
        docker format).
        - If # is first non-whitespace character in a line the line is ignored
        as a comment.
        """)

    env_group.add_argument(
        '--remove-container-env',
        type=arg_parsers.ArgList(),
        action='append',
        metavar='KEY',
        help="""\
        Removes environment variables `KEY` from container declaration Does
        nothing, if a variable is not present.
        """)

    parser.add_argument(
        '--container-stdin',
        action='store_true',
        default=None,
        help="""\
        Sets configuration whether to keep container `STDIN` always open to the
        specified value.
        """)

    parser.add_argument(
        '--container-tty',
        action='store_true',
        default=None,
        help="""\
        Sets configuration whether to allocate a pseudo-TTY for the container
        to the specified value.
        """)

    parser.add_argument(
        '--container-restart-policy',
        choices=['never', 'on-failure', 'always'],
        metavar='POLICY',
        type=lambda val: val.lower(),
        help="""\
        Sets container restart policy to the specified value.
        """)

  def Run(self, args):
    """Issues requests necessary to update Container."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    instance_ref = instances_flags.INSTANCE_ARG.ResolveAsResource(
        args,
        holder.resources,
        scope_lister=instances_flags.GetInstanceZoneScopeLister(client))

    # fetch the Instance resource
    instance = client.apitools_client.instances.Get(
        client.messages.ComputeInstancesGetRequest(**instance_ref.AsDict()))

    # find gce-container-declaration metadata entry
    for metadata in instance.metadata.items:
      if metadata.key == containers_utils.GCE_CONTAINER_DECLARATION:
        # update gce-container-declaration
        containers_utils.UpdateMetadata(metadata, args)

        # update Google Compute Engine resource
        operation = client.apitools_client.instances.SetMetadata(
            client.messages.ComputeInstancesSetMetadataRequest(
                metadata=instance.metadata, **instance_ref.AsDict()))

        operation_ref = holder.resources.Parse(
            operation.selfLink, collection='compute.zoneOperations')

        operation_poller = poller.Poller(client.apitools_client.instances)
        set_metadata_waiter = waiter.WaitFor(
            operation_poller, operation_ref,
            'Updating specification of container [{0}]'.format(
                instance_ref.Name()))

        if (instance.status ==
            client.messages.Instance.StatusValueValuesEnum.TERMINATED):
          return set_metadata_waiter
        elif (instance.status ==
              client.messages.Instance.StatusValueValuesEnum.SUSPENDED):
          return self.StopVm(holder, instance_ref)
        else:
          self.StopVm(holder, instance_ref)
          return self.StartVm(holder, instance_ref)

    raise containers_utils.NoGceContainerDeclarationMetadataKey()

  def StopVm(self, holder, instance_ref):
    """Stop the Virtual Machine."""
    client = holder.client
    operation = client.apitools_client.instances.Stop(
        client.messages.ComputeInstancesStopRequest(
            **instance_ref.AsDict()))

    operation_ref = holder.resources.Parse(
        operation.selfLink, collection='compute.zoneOperations')

    operation_poller = poller.Poller(client.apitools_client.instances)
    return waiter.WaitFor(
        operation_poller, operation_ref,
        'Stopping instance [{0}]'.format(instance_ref.Name()))

  def StartVm(self, holder, instance_ref):
    """Start the Virtual Machine."""
    client = holder.client
    operation = client.apitools_client.instances.Start(
        client.messages.ComputeInstancesStartRequest(
            **instance_ref.AsDict()))

    operation_ref = holder.resources.Parse(
        operation.selfLink, collection='compute.zoneOperations')

    operation_poller = poller.Poller(client.apitools_client.instances)
    return waiter.WaitFor(
        operation_poller, operation_ref,
        'Starting instance [{0}]'.format(instance_ref.Name()))

UpdateContainer.detailed_help = {
    'brief':
        """\
    Updates Google Compute engine virtual machine instances running container
    images.
    """,
    'DESCRIPTION':
        """\
    *{command}* updates Google Compute Engine virtual
    machines that runs a Docker image. For example:

      $ {command} instance-1 --zone us-central1-a \
        --container-image=gcr.io/google-containers/busybox

    updates an instance called instance-1, in the us-central1-a zone,
    to run the 'busybox' image.

    For more examples, refer to the *EXAMPLES* section below.
    """,
    'EXAMPLES':
        """\
    To run the gcr.io/google-containers/busybox image on an instance named
    'instance-1' that executes 'echo "Hello world"' as a run command, run:

      $ {command} instance-1 \
        --container-image=gcr.io/google-containers/busybox \
        --container-command='echo "Hello world"'

    To run the gcr.io/google-containers/busybox image in privileged mode, run:

      $ {command} instance-1 \
        --container-image=gcr.io/google-containers/busybox \
        --container-privileged
    """
}
