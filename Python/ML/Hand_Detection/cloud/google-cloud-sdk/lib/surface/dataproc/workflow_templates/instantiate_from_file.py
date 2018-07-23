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
"""Instantiate a workflow template from a file."""
import uuid

from googlecloudsdk.api_lib.dataproc import dataproc as dp
from googlecloudsdk.api_lib.dataproc import util
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.dataproc import flags
from googlecloudsdk.core import log


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class InstantiateFromFile(base.CreateCommand):
  """Instantiate a workflow template from a file."""

  @staticmethod
  def Args(parser):
    flags.AddFileFlag(parser, 'workflow template', 'run')
    base.ASYNC_FLAG.AddToParser(parser)

  def Run(self, args):
    dataproc = dp.Dataproc(self.ReleaseTrack())
    msgs = dataproc.messages

    # Generate uuid for request.
    instance_id = uuid.uuid4().hex
    regions_ref = util.ParseRegion(dataproc)
    # Read template from YAML file.
    template = util.ReadYaml(args.file, msgs.WorkflowTemplate)

    # Send instantiate inline request.
    request = \
      msgs.DataprocProjectsRegionsWorkflowTemplatesInstantiateInlineRequest(
          instanceId=instance_id,
          parent=regions_ref.RelativeName(),
          workflowTemplate=template)
    operation = \
      dataproc.client.projects_regions_workflowTemplates.InstantiateInline(
          request)
    if args.async:
      log.status.Print('Instantiating [{0}] with operation [{1}].'.format(
          template.id, operation.name))
      return
    operation = util.WaitForWorkflowTemplateOperation(dataproc, operation)
    return operation
