# Copyright 2015 Google Inc. All Rights Reserved.
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

"""Creates or updates a Google Cloud Function."""
from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.compute import utils
from googlecloudsdk.api_lib.functions import util as api_util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.functions import flags
from googlecloudsdk.command_lib.functions.deploy import labels_util
from googlecloudsdk.command_lib.functions.deploy import source_util
from googlecloudsdk.command_lib.functions.deploy import trigger_util
from googlecloudsdk.command_lib.util.args import labels_util as args_labels_util
from googlecloudsdk.core import log


def _Run(args, enable_runtime=False):
  """Run a function deployment with the given args."""
  # Check for labels that start with `deployment`, which is not allowed.
  labels_util.CheckNoDeploymentLabels('--remove-labels', args.remove_labels)
  labels_util.CheckNoDeploymentLabels('--update-labels', args.update_labels)

  # Check that exactly one trigger type is specified properly.
  trigger_util.ValidateTriggerArgs(
      args.trigger_event, args.trigger_resource,
      args.IsSpecified('retry'), args.IsSpecified('trigger_http'))

  trigger_params = trigger_util.GetTriggerEventParams(
      args.trigger_http, args.trigger_bucket, args.trigger_topic,
      args.trigger_event, args.trigger_resource)

  function_ref = api_util.GetFunctionRef(args.name)
  function_url = function_ref.RelativeName()

  messages = api_util.GetApiMessagesModule()

  # Get an existing function or create a new one.
  function = api_util.GetFunction(function_url)
  is_new_function = function is None
  if is_new_function:
    trigger_util.CheckTriggerSpecified(args)
    function = messages.CloudFunction()
    function.name = function_url
  elif trigger_params:
    # If the new deployment would implicitly change the trigger_event type
    # raise error
    trigger_util.CheckLegacyTriggerUpdate(function.eventTrigger,
                                          trigger_params['trigger_event'])

  # Keep track of which fields are updated in the case of patching.
  updated_fields = []

  # Populate function properties based on args.
  if args.entry_point:
    function.entryPoint = args.entry_point
    updated_fields.append('entryPoint')
  if args.timeout:
    function.timeout = '{}s'.format(args.timeout)
    updated_fields.append('timeout')
  if args.memory:
    function.availableMemoryMb = utils.BytesToMb(args.memory)
    updated_fields.append('availableMemoryMb')
  if enable_runtime:
    if args.IsSpecified('runtime'):
      function.runtime = args.runtime
      updated_fields.append('runtime')

  # Populate trigger properties of function based on trigger args.
  if args.trigger_http:
    function.httpsTrigger = messages.HttpsTrigger()
    function.eventTrigger = None
    updated_fields.extend(['eventTrigger', 'httpsTrigger'])
  if trigger_params:
    function.eventTrigger = trigger_util.CreateEventTrigger(**trigger_params)
    function.httpsTrigger = None
    updated_fields.extend(['eventTrigger', 'httpsTrigger'])
  if args.IsSpecified('retry'):
    updated_fields.append('eventTrigger.failurePolicy')
    if args.retry:
      function.eventTrigger.failurePolicy = messages.FailurePolicy()
      function.eventTrigger.failurePolicy.retry = messages.Retry()
    else:
      function.eventTrigger.failurePolicy = None
  elif function.eventTrigger:
    function.eventTrigger.failurePolicy = None

  # Populate source properties of function based on source args.
  # Only Add source to function if its explicitly provided, a new function,
  # using a stage budget or deploy of an existing function that previously
  # used local source.
  if (args.source or args.stage_bucket or is_new_function or
      function.sourceUploadUrl):
    updated_fields.extend(source_util.SetFunctionSourceProps(
        function, function_ref, args.source, args.stage_bucket))

  # Apply label args to function
  if labels_util.SetFunctionLabels(function, args.update_labels,
                                   args.remove_labels, args.clear_labels):
    updated_fields.append('labels')

  if is_new_function:
    return api_util.CreateFunction(function)
  if updated_fields:
    return api_util.PatchFunction(function, updated_fields)
  log.status.Print('Nothing to update.')


@base.ReleaseTracks(base.ReleaseTrack.BETA, base.ReleaseTrack.GA)
class Deploy(base.Command):
  """Create or update a Google Cloud Function."""

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    # Add args for function properties
    flags.AddFunctionNameArg(parser)
    flags.AddFunctionMemoryFlag(parser)
    flags.AddFunctionTimeoutFlag(parser)
    flags.AddFunctionRetryFlag(parser)
    args_labels_util.AddUpdateLabelsFlags(
        parser,
        extra_update_message=
        ' ' + labels_util.NO_LABELS_STARTING_WITH_DEPLOY_MESSAGE,
        extra_remove_message=
        ' ' + labels_util.NO_LABELS_STARTING_WITH_DEPLOY_MESSAGE)

    # Add args for specifying the function source code
    flags.AddSourceFlag(parser)
    flags.AddStageBucketFlag(parser)
    flags.AddEntryPointFlag(parser)

    # Add args for specifying the function trigger
    flags.AddTriggerFlagGroup(parser)

    flags.AddRegionFlag(
        parser,
        help_text='The region in which the function will run.',
    )

  def Run(self, args):
    return _Run(args)


@base.ReleaseTracks(base.ReleaseTrack.ALPHA)
class DeployAlpha(base.Command):
  """Create or update a Google Cloud Function."""

  @staticmethod
  def Args(parser):
    """Register flags for this command."""
    Deploy.Args(parser)
    flags.AddRuntimeFlag(parser)

  def Run(self, args):
    return _Run(args, enable_runtime=True)
