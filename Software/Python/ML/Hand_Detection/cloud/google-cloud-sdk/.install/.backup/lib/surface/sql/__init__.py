# Copyright 2013 Google Inc. All Rights Reserved.
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

"""The super-group for the sql CLI.

The fact that this is a directory with
an __init__.py in it makes it a command group. The methods written below will
all be called by calliope (though they are all optional).
"""
from __future__ import absolute_import
from __future__ import unicode_literals
import argparse
import os
import re

from googlecloudsdk.api_lib.util import apis
from googlecloudsdk.calliope import actions
from googlecloudsdk.calliope import base
from googlecloudsdk.calliope import exceptions
from googlecloudsdk.core import properties

_ACTIVE_VERSIONS = [
    'v1beta3',
    'v1beta4',
]

DETAILED_HELP = {
    'DESCRIPTION': """\
        The gcloud sql command group lets you create and manage Google Cloud SQL
        databases.

        Cloud SQL is a fully-managed database service that makes it easy to set
        up, maintain, manage, and administer your relational MySQL databases in
        the cloud.

        More information on Cloud SQL can be found here:
        https://cloud.google.com/sql and detailed documentation can be found
        here: https://cloud.google.com/sql/docs/
        """,
}


def _Args(parser):
  parser.add_argument(
      '--api-version',
      hidden=True,
      help='THIS ARGUMENT NEEDS HELP TEXT.',
      choices=_ACTIVE_VERSIONS,
      action=actions.StoreProperty(
          properties.VALUES.api_endpoint_overrides.sql))


@base.ReleaseTracks(base.ReleaseTrack.GA)
class SQL(base.Group):
  """Manage Cloud SQL databases."""

  @staticmethod
  def Args(parser):
    _Args(parser)

  def Filter(self, context, args):
    del context, args
    base.DisableUserProjectQuota()


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class SQLBeta(base.Group):
  """Create and manage Google Cloud SQL databases."""
  detailed_help = DETAILED_HELP

  @staticmethod
  def Args(parser):
    _Args(parser)

  def Filter(self, context, args):
    del context, args
    base.DisableUserProjectQuota()
