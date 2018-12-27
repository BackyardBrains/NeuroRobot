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
"""The main command group for Cloud Composer."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.calliope import base


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class Composer(base.Group):
  """Cloud Composer command groups.

  Cloud Composer is a managed Apache Airflow service that helps you create,
  schedule, monitor and manage workflows. Cloud Composer automation helps you
  create Airflow environments quickly and use Airflow-native tools, such as the
  powerful Airflow web interface and command line tools, so you can focus on
  your workflows and not your infrastructure.

  ## EXAMPLES

  To see how to create and manage environments, run:

      $ {command} environments --help

  To see how to manage long-running operations, run:

      $ {command} operations --help
  """
