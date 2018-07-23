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
"""Create workflow template command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.dataproc import dataproc as dp
from googlecloudsdk.api_lib.dataproc import util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.dataproc import flags
from googlecloudsdk.command_lib.util.args import labels_util


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class Create(base.CreateCommand):
  """Create a workflow template."""

  @staticmethod
  def Args(parser):
    labels_util.AddCreateLabelsFlags(parser)
    flags.AddTemplateFlag(parser, 'create')

  def Run(self, args):
    dataproc = dp.Dataproc(self.ReleaseTrack())
    messages = dataproc.messages

    template_ref = util.ParseWorkflowTemplates(args.template, dataproc)
    regions_ref = util.ParseRegion(dataproc)

    workflow_template = messages.WorkflowTemplate(
        id=args.template, name=template_ref.RelativeName(),
        labels=labels_util.ParseCreateArgs(
            args, messages.WorkflowTemplate.LabelsValue))

    request = messages.DataprocProjectsRegionsWorkflowTemplatesCreateRequest(
        parent=regions_ref.RelativeName(), workflowTemplate=workflow_template)

    template = dataproc.client.projects_regions_workflowTemplates.Create(
        request)
    return template
