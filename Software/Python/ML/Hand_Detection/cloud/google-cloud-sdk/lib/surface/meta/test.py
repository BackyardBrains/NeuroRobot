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
"""The `gcloud meta test` command."""

from __future__ import absolute_import
from __future__ import print_function
import os
import signal
import sys
import time

from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import parser_completer
from googlecloudsdk.calliope import parser_errors
from googlecloudsdk.command_lib.compute import completers
from googlecloudsdk.core import exceptions
from googlecloudsdk.core import execution_utils
from googlecloudsdk.core import module_util
from googlecloudsdk.core.console import console_io


class Test(base.Command):
  """Run miscellaneous gcloud command and CLI test scenarios.

  This command sets up scenarios for testing the gcloud command and CLI.
  """

  @staticmethod
  def Args(parser):
    parser.add_argument(
        'name',
        nargs='*',
        completer=completers.TestCompleter,
        help='command_lib.compute.TestCompleter instance name test.')
    scenarios = parser.add_mutually_exclusive_group()
    scenarios.add_argument(
        '--argumenterror-outside-argparse',
        action='store_true',
        help=('Trigger a calliope.parser_errors.ArgumentError exception '
              'outside of argparse.'))
    scenarios.add_argument(
        '--core-exception',
        action='store_true',
        help='Trigger a core exception.')
    scenarios.add_argument(
        '--exec-file',
        metavar='SCRIPT_FILE',
        help='Runs `bash SCRIPT_FILE`.')
    scenarios.add_argument(
        '--interrupt',
        action='store_true',
        help='Kill the command with SIGINT.')
    scenarios.add_argument(
        '--is-interactive',
        action='store_true',
        help=('Call console_io.IsInteractive(heuristic=True) and exit 0 '
              'if the return value is True, 1 if False.'))
    scenarios.add_argument(
        '--sleep',
        metavar='SECONDS',
        type=float,
        default=0.0,
        help='Sleep for SECONDS seconds and exit.')
    scenarios.add_argument(
        '--prompt-completer',
        metavar='MODULE_PATH',
        help=('Call console_io.PromptResponse() with a MODULE_PATH completer '
              'and print the response on the standard output.'))
    scenarios.add_argument(
        '--uncaught-exception',
        action='store_true',
        help='Trigger an exception that is not caught.')

  def _RunArgumenterrorOutsideArgparse(self, args):
    raise parser_errors.RequiredError(argument='--some-flag')

  def _RunCoreException(self, args):
    raise exceptions.Error('Some core exception.')

  def _RunExecFile(self, args):
    # We may want to add a timeout, though that will complicate the logic a bit
    execution_utils.Exec(['bash', args.exec_file])

  def _RunIsInteractive(self, args):
    sys.exit(int(not console_io.IsInteractive(heuristic=True)))

  def _RunInterrupt(self, args):
    try:
      # Windows hackery to simulate ^C and wait for it to register.
      # NOTICE: This only works if this command is run from the console.
      os.kill(os.getpid(), signal.CTRL_C_EVENT)
      time.sleep(1)
    except AttributeError:
      # Back to normal where ^C is SIGINT and it works immediately.
      os.kill(os.getpid(), signal.SIGINT)
    raise exceptions.Error('SIGINT delivery failed.')

  def _RunPromptCompleter(self, args):
    completer_class = module_util.ImportModule(args.prompt_completer)
    choices = parser_completer.ArgumentCompleter(completer_class, args)
    response = console_io.PromptResponse('Complete this: ', choices=choices)
    print(response)

  def _RunSleep(self, args):
    time.sleep(args.sleep)

  def _RunUncaughtException(self, args):
    raise ValueError('Catch me if you can.')

  def Run(self, args):
    if args.argumenterror_outside_argparse:
      self._RunArgumenterrorOutsideArgparse(args)
    elif args.core_exception:
      self._RunCoreException(args)
    elif args.exec_file:
      self._RunExecFile(args)
    elif args.interrupt:
      self._RunInterrupt(args)
    elif args.is_interactive:
      self._RunIsInteractive(args)
    elif args.prompt_completer:
      self._RunPromptCompleter(args)
    elif args.sleep:
      self._RunSleep(args)
    elif args.uncaught_exception:
      self._RunUncaughtException(args)
