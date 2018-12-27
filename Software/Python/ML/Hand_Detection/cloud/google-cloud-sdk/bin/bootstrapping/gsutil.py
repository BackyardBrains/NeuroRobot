#!/usr/bin/env python
#
# Copyright 2013 Google Inc. All Rights Reserved.
#

"""A convenience wrapper for starting gsutil."""

import os
import sys


import bootstrapping
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import config
from googlecloudsdk.core import metrics
from googlecloudsdk.core import properties
from googlecloudsdk.core.credentials import gce as c_gce
from googlecloudsdk.core.util import encoding


def _MaybeAddBotoOption(args, section, name, value):
  if value is None:
    return
  args.append('-o')
  args.append('{section}:{name}={value}'.format(
      section=section, name=name, value=value))


def main():
  """Launches gsutil."""

  project, account = bootstrapping.GetActiveProjectAndAccount()
  pass_credentials = (
      properties.VALUES.core.pass_credentials_to_gsutil.GetBool() and
      not properties.VALUES.auth.disable_credentials.GetBool())

  if pass_credentials and account not in c_gce.Metadata().Accounts():
    gsutil_path = config.Paths().LegacyCredentialsGSUtilPath(account)

    # Allow gsutil to only check for the '1' string value, as is done
    # with regard to the 'CLOUDSDK_WRAPPER' environment variable.
    encoding.SetEncodedValue(
        os.environ, 'CLOUDSDK_CORE_PASS_CREDENTIALS_TO_GSUTIL', '1')

    boto_config = encoding.GetEncodedValue(os.environ, 'BOTO_CONFIG', '')
    boto_path = encoding.GetEncodedValue(os.environ, 'BOTO_PATH', '')

    # We construct a BOTO_PATH that tacks the refresh token config
    # on the end.
    if boto_config:
      boto_path = os.pathsep.join([boto_config, gsutil_path])
    elif boto_path:
      boto_path = os.pathsep.join([boto_path, gsutil_path])
    else:
      path_parts = ['/etc/boto.cfg',
                    os.path.expanduser(os.path.join('~', '.boto')),
                    gsutil_path]
      boto_path = os.pathsep.join(path_parts)

    encoding.SetEncodedValue(os.environ, 'BOTO_CONFIG', None)
    encoding.SetEncodedValue(os.environ, 'BOTO_PATH', boto_path)

  # Tell gsutil whether gcloud analytics collection is enabled.
  encoding.SetEncodedValue(
      os.environ, 'GA_CID', metrics.GetCIDIfMetricsEnabled())

  args = []

  _MaybeAddBotoOption(args, 'GSUtil', 'default_project_id', project)
  if pass_credentials and account in c_gce.Metadata().Accounts():
    # Tell gsutil to look for GCE service accounts.
    _MaybeAddBotoOption(args, 'GoogleCompute', 'service_account', 'default')

  proxy_params = properties.VALUES.proxy
  proxy_address = proxy_params.address.Get()
  if proxy_address:
    _MaybeAddBotoOption(args, 'Boto', 'proxy', proxy_address)
    _MaybeAddBotoOption(args, 'Boto', 'proxy_port', proxy_params.port.Get())
    _MaybeAddBotoOption(args, 'Boto', 'proxy_rdns', proxy_params.rdns.GetBool())
    _MaybeAddBotoOption(args, 'Boto', 'proxy_user', proxy_params.username.Get())
    _MaybeAddBotoOption(args, 'Boto', 'proxy_pass', proxy_params.password.Get())
  disable_ssl = properties.VALUES.auth.disable_ssl_validation.GetBool()
  _MaybeAddBotoOption(args, 'Boto', 'https_validate_certificates',
                      None if disable_ssl is None else not disable_ssl)
  _MaybeAddBotoOption(args, 'Boto', 'ca_certificates_file',
                      properties.VALUES.core.custom_ca_certs_file.Get())

  bootstrapping.ExecutePythonTool('platform/gsutil', 'gsutil', *args)


if __name__ == '__main__':
  try:
    version = bootstrapping.GetFileContents('platform/gsutil', 'VERSION')
    bootstrapping.CommandStart('gsutil', version=version)

    blacklist = {
        'update': 'To update, run: gcloud components update',
    }

    bootstrapping.CheckForBlacklistedCommand(sys.argv, blacklist, warn=True,
                                             die=True)
    # Don't call bootstrapping.PreRunChecks because anonymous access is
    # supported for some endpoints. gsutil will output the appropriate
    # error message upon receiving an authentication error.
    bootstrapping.CheckUpdates('gsutil')
    main()
  except Exception as e:  # pylint: disable=broad-except
    exceptions.HandleError(e, 'gsutil')
