# Copyright 2016 Google Inc. All Rights Reserved.
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
"""Command for switching network mode."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import base_classes
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions as exceptions
from googlecloudsdk.command_lib.compute.networks import flags
from googlecloudsdk.core import properties
from googlecloudsdk.core.console import console_io


_DEPRECATION_WARNING = (
    '`switch-mode` is deprecated. '
    'Please use `--switch-to-custom-subnet-mode` with `gcloud compute networks '
    'update` instead.')


_DEPRECATION_ERROR = (
    '`switch-mode` has been removed. '
    'Please use `--switch-to-custom-subnet-mode` with `gcloud compute networks '
    'update` instead.')


# TODO(b/64980447): Clean up this command flag after 3 months of deprecation.
@base.Deprecate(
    is_removed=True, warning=_DEPRECATION_WARNING, error=_DEPRECATION_ERROR)
class SwitchMode(base.SilentCommand):
  """Switch network mode."""

  @staticmethod
  def Args(parser):
    parser.add_argument(
        '--mode',
        help=('The target mode of the network. Only support "custom" now.'),
        required=True)
    parser.add_argument(
        'name',
        completer=flags.NetworksCompleter,
        help='The name of the network for which to switch mode.')

  def Run(self, args):
    """Issues requests necessary for switching to custom mode."""
    holder = base_classes.ComputeApiHolder(self.ReleaseTrack())
    client = holder.client

    if args.mode != 'custom':
      raise exceptions.InvalidArgumentException(
          '--mode', 'Only switching to custom mode is supported now.')

    if not console_io.PromptContinue(
        message='Network [{0}] will be switched to {1} mode.'.format(
            args.name, args.mode) + ' This operation cannot be undone.',
        default=True):
      raise exceptions.ToolException('Operation aborted by user.')
    request = client.messages.ComputeNetworksSwitchToCustomModeRequest(
        network=args.name,
        project=properties.VALUES.core.project.GetOrFail())

    return client.MakeRequests([(client.apitools_client.networks,
                                 'SwitchToCustomMode', request)])


SwitchMode.detailed_help = {
    'brief': 'Switch the mode of a Google Compute Engine network',
    'DESCRIPTION': """\
        *{command}* is used to change the mode of a network. Currently, only
        changing from auto to custom mode is supported.
        """,
    'EXAMPLES': """\
        To switch ``NETWORK'' to custom subnet mode, run:

          $ {command} NETWORK --mode custom
        """,
}
