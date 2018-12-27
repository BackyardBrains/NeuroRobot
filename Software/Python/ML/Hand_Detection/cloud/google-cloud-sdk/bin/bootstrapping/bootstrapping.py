# Copyright 2013 Google Inc. All Rights Reserved.

"""Common bootstrapping functionality used by the wrapper scripts."""

# Disables import order warning and unused import.  Setup changes the python
# path so cloud sdk imports will actually work, so it must come first.
# pylint: disable=C6203
# pylint: disable=W0611
import setup

import json
import os
import sys

from googlecloudsdk.core import config
from googlecloudsdk.core import execution_utils
from googlecloudsdk.core import metrics
from googlecloudsdk.core import properties
from googlecloudsdk.core.credentials import store as c_store
from googlecloudsdk.core.updater import local_state
from googlecloudsdk.core.updater import update_manager
from googlecloudsdk.core.util import encoding
from googlecloudsdk.core.util import files


BOOTSTRAPPING_DIR = os.path.dirname(os.path.realpath(__file__))
BIN_DIR = os.path.dirname(BOOTSTRAPPING_DIR)
SDK_ROOT = os.path.dirname(BIN_DIR)


def _FullPath(tool_dir, exec_name):
  return os.path.join(SDK_ROOT, tool_dir, exec_name)


def ExecutePythonTool(tool_dir, exec_name, *args):
  """Execute the given python script with the given args and command line.

  Args:
    tool_dir: the directory the tool is located in
    exec_name: additional path to the executable under the tool_dir
    *args: args for the command
  """
  _ExecuteTool(
      execution_utils.ArgsForPythonTool(_FullPath(tool_dir, exec_name), *args))


def ExecuteJarTool(java_bin, jar_dir, jar_name, classname, flags=None, *args):
  """Execute a given jar with the given args and command line.

  Args:
    java_bin: str, path to the system Java binary
    jar_dir: str, the directory the jar is located in
    jar_name: str, file name of the jar under tool_dir
    classname: str, name of the main class in the jar
    flags: [str], flags for the java binary
    *args: args for the command
  """
  flags = flags or []
  jar_path = _FullPath(jar_dir, jar_name)
  java_args = ['-cp', jar_path] + flags + [classname] + list(args)
  _ExecuteTool(
      execution_utils.ArgsForExecutableTool(java_bin, *java_args))


def ExecuteShellTool(tool_dir, exec_name, *args):
  """Execute the given bash script with the given args.

  Args:
    tool_dir: the directory the tool is located in
    exec_name: additional path to the executable under the tool_dir
    *args: args for the command
  """
  _ExecuteTool(
      execution_utils.ArgsForExecutableTool(_FullPath(tool_dir, exec_name),
                                            *args))


def ExecuteCMDTool(tool_dir, exec_name, *args):
  """Execute the given batch file with the given args.

  Args:
    tool_dir: the directory the tool is located in
    exec_name: additional path to the executable under the tool_dir
    *args: args for the command
  """
  _ExecuteTool(
      execution_utils.ArgsForCMDTool(_FullPath(tool_dir, exec_name), *args))


def _GetToolEnv():
  env = dict(os.environ)
  encoding.SetEncodedValue(env, 'CLOUDSDK_WRAPPER', '1')
  encoding.SetEncodedValue(env, 'CLOUDSDK_VERSION', config.CLOUD_SDK_VERSION)
  encoding.SetEncodedValue(env, 'CLOUDSDK_PYTHON',
                           execution_utils.GetPythonExecutable())
  return env


def _ExecuteTool(args):
  """Executes a new tool with the given args, plus the args from the cmdline.

  Args:
    args: [str], The args of the command to execute.
  """
  execution_utils.Exec(args + sys.argv[1:], env=_GetToolEnv())


def GetDefaultInstalledComponents():
  """Gets the list of components to install by default.

  Returns:
    list(str), The component ids that should be installed.  It will return []
    if there are no default components, or if there is any error in reading
    the file with the defaults.
  """
  default_components_file = os.path.join(BOOTSTRAPPING_DIR,
                                         '.default_components')
  try:
    with open(default_components_file) as f:
      return json.load(f)
  # pylint:disable=bare-except, If the file does not exist or is malformed,
  # we don't want to expose this as an error.  Setup will just continue
  # without installing any components by default and will tell the user how
  # to install the components they want manually.
  except:
    pass
  return []


def CheckForBlacklistedCommand(args, blacklist, warn=True, die=False):
  """Blacklist certain subcommands, and warn the user.

  Args:
    args: the command line arguments, including the 0th argument which is
      the program name.
    blacklist: a map of blacklisted commands to the messages that should be
      printed when they're run.
    warn: if true, print a warning message.
    die: if true, exit.

  Returns:
    True if a command in the blacklist is being indicated by args.

  """
  bad_arg = None
  for arg in args[1:]:
    if arg and arg[0] is '-':
      continue
    if arg in blacklist:
      bad_arg = arg
      break

  blacklisted = bad_arg is not None

  if blacklisted:
    if warn:
      sys.stderr.write('It looks like you are trying to run "%s %s".\n'
                       % (args[0], bad_arg))
      sys.stderr.write('The "%s" command is no longer needed with the '
                       'Cloud SDK.\n' % bad_arg)
      sys.stderr.write(blacklist[bad_arg] + '\n')
      answer = raw_input('Really run this command? (y/N) ')
      if answer in ['y', 'Y']:
        return False

    if die:
      sys.exit(1)

  return blacklisted


def CheckUpdates(command_path):
  """Check for updates and inform the user.

  Args:
    command_path: str, The '.' separated path of the command that is currently
      being run (i.e. gcloud.foo.bar).
  """
  try:
    update_manager.UpdateManager.PerformUpdateCheck(command_path=command_path)
  # pylint:disable=broad-except, We never want this to escape, ever. Only
  # messages printed should reach the user.
  except Exception:
    pass


def CommandStart(command_name, component_id=None, version=None):
  """Logs that the given command is being executed.

  Args:
    command_name: str, The name of the command being executed.
    component_id: str, The component id that this command belongs to.  Used for
      version information if version was not specified.
    version: str, Directly use this version instead of deriving it from
      component.
  """
  if version is None and component_id:
    version = local_state.InstallationState.VersionForInstalledComponent(
        component_id)
  metrics.Executions(command_name, version)


def GetActiveProjectAndAccount():
  """Get the active project name and account for the active credentials.

  For use with wrapping legacy tools that take projects and credentials on
  the command line.

  Returns:
    (str, str), A tuple whose first element is the project, and whose second
    element is the account.
  """
  project_name = properties.VALUES.core.project.Get(validate=False)
  account = properties.VALUES.core.account.Get(validate=False)
  return (project_name, account)


def GetFileContents(*path_parts):
  """Returns file content at specified relative path wrt SDK root path."""
  return files.GetFileContents(os.path.join(SDK_ROOT, *path_parts)).strip()


# Register some other sources for credentials and project.
c_store.DevShellCredentialProvider().Register()
c_store.GceCredentialProvider().Register()
