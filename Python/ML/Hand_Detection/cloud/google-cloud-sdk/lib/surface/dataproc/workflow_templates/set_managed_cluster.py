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
"""Set managed cluster for workflow template command."""

from __future__ import absolute_import
from __future__ import unicode_literals
from googlecloudsdk.api_lib.dataproc import compute_helpers
from googlecloudsdk.api_lib.dataproc import dataproc as dp
from googlecloudsdk.api_lib.dataproc import util
from googlecloudsdk.calliope import arg_parsers
from googlecloudsdk.calliope import base
from googlecloudsdk.command_lib.dataproc import clusters
from googlecloudsdk.command_lib.dataproc import flags
from googlecloudsdk.command_lib.util.args import labels_util


@base.ReleaseTracks(base.ReleaseTrack.BETA)
class SetManagedCluster(base.UpdateCommand):
  """Set a managed cluster for the workflow template."""

  @staticmethod
  def Args(parser):
    flags.AddTemplateFlag(parser, 'set managed cluster')
    parser.add_argument(
        '--cluster-name', help='The name of the managed dataproc cluster.')
    clusters.ArgsForClusterRef(parser, beta=True)
    flags.AddMinCpuPlatformArgs(parser, base.ReleaseTrack.BETA)

    # TODO(b/70164645): Consolidate these arguments with the other beta args
    # All arguments for these arguments are duplicated from the cluster creation
    # beta track. There should be a ArgsForClusterRefBeta method in clusters.py
    # that is invoked here so that we don't have to duplicate the arguments.
    parser.add_argument(
        '--max-idle',
        type=arg_parsers.Duration(),
        help="""\
        The duration before cluster is auto-deleted after last job completes,
        such as "2h" or "1d".
        See $ gcloud topic datetimes for information on duration formats.
        """)

    auto_delete_group = parser.add_mutually_exclusive_group()
    auto_delete_group.add_argument(
        '--max-age',
        type=arg_parsers.Duration(),
        help="""\
        The lifespan of the cluster before it is auto-deleted, such as
        "2h" or "1d".
        See $ gcloud topic datetimes for information on duration formats.
        """)

    auto_delete_group.add_argument(
        '--expiration-time',
        type=arg_parsers.Datetime.Parse,
        help="""\
        The time when cluster will be auto-deleted, such as
        "2017-08-29T18:52:51.142Z." See $ gcloud topic datetimes for
        information on time formats.
        """)

    for instance_type in ('master', 'worker'):
      help_msg = """\
      Attaches accelerators (e.g. GPUs) to the {instance_type}
      instance(s).
      """.format(instance_type=instance_type)
      if instance_type == 'worker':
        help_msg += """
      Note:
      No accelerators will be attached to preemptible workers, because
      preemptible VMs do not support accelerators.
      """
      help_msg += """
      *type*::: The specific type (e.g. nvidia-tesla-k80 for nVidia Tesla
      K80) of accelerator to attach to the instances. Use 'gcloud compute
      accelerator-types list' to learn about all available accelerator
      types.

      *count*::: The number of pieces of the accelerator to attach to each
      of the instances. The default value is 1.
      """
      parser.add_argument(
          '--{0}-accelerator'.format(instance_type),
          type=arg_parsers.ArgDict(spec={
              'type': str,
              'count': int,
          }),
          metavar='type=TYPE,[count=COUNT]',
          help=help_msg)

  def Run(self, args):
    dataproc = dp.Dataproc(self.ReleaseTrack())

    template = util.ParseWorkflowTemplates(args.template, dataproc)

    workflow_template = dataproc.GetRegionsWorkflowTemplate(
        template, args.version)

    cluster_name = template.workflowTemplatesId

    compute_resources = compute_helpers.GetComputeResources(
        self.ReleaseTrack(), cluster_name)

    beta = self.ReleaseTrack() == base.ReleaseTrack.BETA
    cluster_config = clusters.GetClusterConfig(
        args, dataproc, template.projectsId, compute_resources, beta)

    labels = labels_util.ParseCreateArgs(
        args, dataproc.messages.ManagedCluster.LabelsValue)

    managed_cluster = dataproc.messages.ManagedCluster(
        clusterName=cluster_name, config=cluster_config, labels=labels)

    workflow_template.placement = dataproc.messages.WorkflowTemplatePlacement(
        managedCluster=managed_cluster)

    response = dataproc.client.projects_regions_workflowTemplates.Update(
        workflow_template)
    return response
