# Copyright 2014 Google Inc. All Rights Reserved.
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

"""Implements the command for SSHing into an instance."""
from __future__ import absolute_import
from __future__ import unicode_literals
import argparse
import sys

from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.compute import completers
from googlecloudsdk.command_lib.compute import flags
from googlecloudsdk.command_lib.compute import scope as compute_scope
from googlecloudsdk.command_lib.compute import ssh_utils
from googlecloudsdk.command_lib.compute.instances import flags as instance_flags
from googlecloudsdk.command_lib.util.ssh import containers
from googlecloudsdk.command_lib.util.ssh import ssh
from googlecloudsdk.core import log
from googlecloudsdk.core.util import retry


def _Args(parser):
  """Argument parsing for ssh, including hook for remote completion."""
  ssh_utils.BaseSSHCLIHelper.Args(parser)

  parser.add_argument(
      '--command',
      help="""\
      A command to run on the virtual machine.

      Runs the command on the target instance and then exits.
      """)

  parser.add_argument(
      '--ssh-flag',
      action='append',
      help="""\
      Additional flags to be passed to *ssh(1)*. It is recommended that flags
      be passed using an assignment operator and quotes. This flag will
      replace occurences of ``%USER%'' and ``%INSTANCE%'' with their
      dereferenced values. Example:

        $ {command} example-instance --zone us-central1-a --ssh-flag="-vvv" --ssh-flag="-L 80:%INSTANCE%:80"

      is equivalent to passing the flags ``--vvv'' and ``-L
      80:162.222.181.197:80'' to *ssh(1)* if the external IP address of
      'example-instance' is 162.222.181.197.
      """)

  parser.add_argument(
      '--container',
      help="""\
          The name or ID of a container inside of the virtual machine instance
          to connect to. This only applies to virtual machines that are using
          a Google Container-Optimized virtual machine image. For more
          information, see [](https://cloud.google.com/compute/docs/containers).
          """)

  parser.add_argument(
      'user_host',
      completer=completers.InstancesCompleter,
      metavar='[USER@]INSTANCE',
      help="""\
      Specifies the instance to SSH into.

      ``USER'' specifies the username with which to SSH. If omitted,
      $USER from the environment is selected.

      ``INSTANCE'' specifies the name of the virtual machine instance to SSH
      into.
      """)

  parser.add_argument(
      'ssh_args',
      nargs=argparse.REMAINDER,
      help="""\
          Flags and positionals passed to the underlying ssh implementation.
          """,
      example="""\
        $ {command} example-instance --zone us-central1-a -- -vvv -L 80:%INSTANCE%:80
      """)

  flags.AddZoneFlag(
      parser,
      resource_type='instance',
      operation_type='connect to')


@base.ReleaseTracks(base.ReleaseTrack.GA)
class SshGA(base.Command):
  """SSH into a virtual machine instance."""

  def __init__(self, *args, **kwargs):
    super(SshGA, self).__init__(*args, **kwargs)
    self._use_internal_ip = False

  @staticmethod
  def Args(parser):
    """Set up arguments for this command.

    Args:
      parser: An argparse.ArgumentParser.
    """
    _Args(parser)

  def Run(self, args):
    """See ssh_utils.BaseSSHCLICommand.Run."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    ssh_helper = ssh_utils.BaseSSHCLIHelper()
    ssh_helper.Run(args)
    user, instance_name = ssh_utils.GetUserAndInstance(args.user_host)
    instance_ref = instance_flags.SSH_INSTANCE_RESOLVER.ResolveResources(
        [instance_name], compute_scope.ScopeEnum.ZONE, args.zone,
        holder.resources,
        scope_lister=instance_flags.GetInstanceZoneScopeLister(client))[0]
    instance = ssh_helper.GetInstance(client, instance_ref)
    project = ssh_helper.GetProject(client, instance_ref.project)
    if args.plain:
      use_oslogin = False
    else:
      user, use_oslogin = ssh_helper.CheckForOsloginAndGetUser(
          instance, project, user, self.ReleaseTrack())
    if self._use_internal_ip:
      ip_address = ssh_utils.GetInternalIPAddress(instance)
    else:
      ip_address = ssh_utils.GetExternalIPAddress(instance)

    remote = ssh.Remote(ip_address, user)

    identity_file = None
    options = None
    if not args.plain:
      identity_file = ssh_helper.keys.key_file
      options = ssh_helper.GetConfig(ssh_utils.HostKeyAlias(instance),
                                     args.strict_host_key_checking)

    extra_flags = ssh.ParseAndSubstituteSSHFlags(args, remote, ip_address)
    remainder = []

    if args.ssh_args:
      remainder.extend(args.ssh_args)

    # Transform args.command into arg list or None if no command
    command_list = args.command.split(' ') if args.command else None
    tty = containers.GetTty(args.container, command_list)
    remote_command = containers.GetRemoteCommand(args.container, command_list)

    cmd = ssh.SSHCommand(remote, identity_file=identity_file,
                         options=options, extra_flags=extra_flags,
                         remote_command=remote_command, tty=tty,
                         remainder=remainder)
    if args.dry_run:
      log.out.Print(' '.join(cmd.Build(ssh_helper.env)))
      return

    if args.plain or use_oslogin:
      keys_newly_added = False
    else:
      keys_newly_added = ssh_helper.EnsureSSHKeyExists(
          client, remote.user, instance, project)

    if keys_newly_added:
      poller = ssh.SSHPoller(
          remote, identity_file=identity_file, options=options,
          extra_flags=extra_flags,
          max_wait_ms=ssh_utils.SSH_KEY_PROPAGATION_TIMEOUT_SEC)
      log.status.Print('Waiting for SSH key to propagate.')
      # TODO(b/35355795): Don't force_connect
      try:
        poller.Poll(ssh_helper.env, force_connect=True)
      except retry.WaitException:
        raise ssh_utils.NetworkError()

    if self._use_internal_ip:
      ssh_helper.PreliminarilyVerifyInstance(instance.id, remote, identity_file,
                                             options)

    return_code = cmd.Run(ssh_helper.env, force_connect=True)
    if return_code:
      # Can't raise an exception because we don't want any "ERROR" message
      # printed; the output from `ssh` will be enough.
      sys.exit(return_code)


@base.ReleaseTracks(base.ReleaseTrack.BETA, base.ReleaseTrack.ALPHA)
class SshBeta(SshGA):
  """SSH into a virtual machine instance."""

  def __init__(self, *args, **kwargs):
    super(SshBeta, self).__init__(*args, **kwargs)

  @staticmethod
  def Args(parser):
    """Set up arguments for this command.

    Args:
      parser: An argparse.ArgumentParser.
    """
    _Args(parser)
    parser.add_argument(
        '--internal-ip', default=False, action='store_true',
        help="""\
        Connect to instances using their internal IP addresses rather than their
        external IP addresses. Use this to connect from one instance to another
        on the same VPC network, over a VPN connection, or between two peered
        VPC networks.

        For this connection to work, you must configure your networks and
        firewall to allow SSH connections to the internal IP address of
        the instance to which you want to connect.

        To learn how to use this flag, see
        [](https://cloud.google.com/compute/docs/instances/connecting-advanced#sshbetweeninstances).
        """)

  def Run(self, args):
    """See SshGA.Run."""
    self._use_internal_ip = args.internal_ip
    super(SshBeta, self).Run(args)


def DetailedHelp(version):
  """Construct help text based on the command release track."""
  detailed_help = {
      'brief': 'SSH into a virtual machine instance',
      'DESCRIPTION': """\
        *{command}* is a thin wrapper around the *ssh(1)* command that
        takes care of authentication and the translation of the
        instance name into an IP address.

        The default network comes preconfigured to allow ssh access to
        all VMs. If the default network was edited, or if not using the
        default network, you may need to explicitly enable ssh access by adding
        a firewall-rule:

          $ gcloud compute firewall-rules create --network=NETWORK \
            default-allow-ssh --allow tcp:22

        This command does not work for Windows VMs.

        This command ensures that the user's public SSH key is present
        in the project's metadata. If the user does not have a public
        SSH key, one is generated using *ssh-keygen(1)* (if the `--quiet`
        flag is given, the generated key will have an empty passphrase).
        """,
      'EXAMPLES': """\
        To SSH into 'example-instance' in zone ``us-central1-a'', run:

          $ {command} example-instance --zone us-central1-a

        You can also run a command on the virtual machine. For
        example, to get a snapshot of the guest's process tree, run:

          $ {command} example-instance --zone us-central1-a --command "ps -ejH"

        If you are using the Google Container-Optimized virtual machine image,
        you can SSH into one of your containers with:

          $ {command} example-instance --zone us-central1-a --container CONTAINER
        """,
  }
  if version == 'BETA':
    detailed_help['DESCRIPTION'] = """\
        *{command}* is a thin wrapper around the *ssh(1)* command that
        takes care of authentication and the translation of the
        instance name into an IP address.

        The default network comes preconfigured to allow ssh access to
        all VMs. If the default network was edited, or if not using the
        default network, you may need to explicitly enable ssh access by adding
        a firewall-rule:

          $ gcloud compute firewall-rules create --network=NETWORK \
            default-allow-ssh --allow tcp:22

        This command does not work for Windows VMs.

        This command uses the Compute Accounts API to ensure that the user's
        public SSH key is availibe to the VM. This form of key management
        will only work with VMs configured to work with the Compute Accounts
        API. If the user does not have a public SSH key, one is generated using
        *ssh-keygen(1)* (if `the --quiet` flag is given, the generated key will
        have an empty passphrase).

        """
  return detailed_help

SshGA.detailed_help = DetailedHelp('GA')
SshBeta.detailed_help = DetailedHelp('BETA')
