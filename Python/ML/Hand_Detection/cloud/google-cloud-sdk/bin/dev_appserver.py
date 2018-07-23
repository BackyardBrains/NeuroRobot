#!/usr/bin/env python
#
# Copyright 2015 Google Inc. All Rights Reserved.
#

"""A convenience wrapper for starting dev_appserver for appengine for python."""

import os
import sys

import bootstrapping.bootstrapping as bootstrapping
from googlecloudsdk.api_lib.app import wrapper_util
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import metrics
from googlecloudsdk.core.updater import update_manager
from googlecloudsdk.core.util import platforms


def main():
  """Launches dev_appserver.py."""
  runtimes = wrapper_util.GetRuntimes(sys.argv[1:])
  components = wrapper_util.GetComponents(runtimes)
  options = wrapper_util.ParseDevAppserverFlags(sys.argv[1:])
  if options.support_datastore_emulator:
    components.append('cloud-datastore-emulator')
  update_manager.UpdateManager.EnsureInstalledAndRestart(
      components,
      command=__file__)

  args = [
      '--skip_sdk_update_check=True'
  ]

  google_analytics_client_id = metrics.GetCIDIfMetricsEnabled()
  google_analytics_user_agent = metrics.GetUserAgentIfMetricsEnabled()
  if google_analytics_client_id:
    args.extend([
        '--google_analytics_client_id={}'.format(google_analytics_client_id),
        '--google_analytics_user_agent={}'.format(google_analytics_user_agent)
    ])

  # Pass the path to cloud datastore emulator to dev_appserver.
  sdk_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
  emulator_dir = os.path.join(sdk_root, 'platform', 'cloud-datastore-emulator')
  emulator_script = (
      'cloud_datastore_emulator.cmd' if platforms.OperatingSystem.IsWindows()
      else 'cloud_datastore_emulator')
  args.append('--datastore_emulator_cmd={}'.format(
      os.path.join(emulator_dir, emulator_script)))

  bootstrapping.ExecutePythonTool(
      os.path.join('platform', 'google_appengine'), 'dev_appserver.py', *args)


if __name__ == '__main__':
  try:
    bootstrapping.CommandStart('dev_appserver', component_id='core')
    bootstrapping.CheckUpdates('dev_appserver')
    main()
  except Exception as e:  # pylint: disable=broad-except
    exceptions.HandleError(e, 'dev_appserver')
