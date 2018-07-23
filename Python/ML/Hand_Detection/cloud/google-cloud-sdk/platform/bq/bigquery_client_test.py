#!/usr/bin/env python
# Copyright 2011 Google Inc. All Rights Reserved.

"""Tests for bigquery_client.py."""

__author__ = 'craigcitro@google.com (Craig Citro)'

import itertools
import json
import tempfile

import httplib2
import mock
import gflags as flags
from google.apputils import flagsaver
from google.apputils import googletest

import bigquery_client
# pylint: disable=unused-import
import bq_flags
# pylint: enable=unused-import


FLAGS = flags.FLAGS

_TABLE_INFO = """
{
  "creationTime": "1513021634803",
  "id": "bigquerytestdefault:vimota.table1",
  "kind": "bigquery#table",
  "lastModifiedTime": "1513021634803",
  "numBytes": "0",
  "numLongTermBytes": "0",
  "numRows": "0",
  "schema": {
    "fields": [
      {
        "name": "ts",
        "type": "TIMESTAMP"
      },
      {
        "name": "field1",
        "type": "STRING"
      },
      {
        "name": "field2",
        "type": "INTEGER"
      }
    ]
  },
  "tableReference": {
    "datasetId": "vimota",
    "projectId": "bigquerytestdefault",
    "tableId": "table1"
  },
  "timePartitioning": {
    "field": "ts",
    "type": "DAY",
    "expirationMs": "10"
  },
  "type": "TABLE"
}
"""


class BigqueryClientTest(googletest.TestCase):

  def setUp(self):
    self._saved_flags = flagsaver.SaveFlagValues()
    self.client = bigquery_client.BigqueryClient(api='http', api_version='')
    self.reference_tests = {
        'prj:': ('prj', '', ''),
        'example.com:prj': ('example.com:prj', '', ''),
        'example.com:prj-2': ('example.com:prj-2', '', ''),
        'www.example.com:prj': ('www.example.com:prj', '', ''),
        'prj:ds': ('prj', 'ds', ''),
        'example.com:prj:ds': ('example.com:prj', 'ds', ''),
        'prj:ds.tbl': ('prj', 'ds', 'tbl'),
        'example.com:prj:ds.tbl': ('example.com:prj', 'ds', 'tbl'),
        'prefix::example:buganizer.metadata.all': (
            'prefix::example', 'buganizer.metadata', 'all'),
        'prefix.example:buganizer.metadata.all': (
            'prefix.example', 'buganizer.metadata', 'all'),
        'prefix.example:foo_metrics.bar_walkups_sanitised.all': (
            'prefix.example', 'foo_metrics.bar_walkups_sanitised', 'all'),
        }
    self.parse_tests = self.reference_tests.copy()
    self.parse_tests.update({
        'ds.': ('', 'ds', ''),
        'ds.tbl': ('', 'ds', 'tbl'),
        'tbl': ('', '', 'tbl'),
        })
    self.field_names = ('projectId', 'datasetId', 'tableId')

  def tearDown(self):
    flagsaver.RestoreFlagValues(self._saved_flags)

  @staticmethod
  def _LengthToType(parts):
    if len(parts) == 1:
      return bigquery_client.ApiClientHelper.ProjectReference
    if len(parts) == 2:
      return bigquery_client.ApiClientHelper.DatasetReference
    if len(parts) == 3:
      return bigquery_client.ApiClientHelper.TableReference
    return None

  def _GetReference(self, parts):
    parts = filter(bool, parts)
    reference_type = BigqueryClientTest._LengthToType(parts)
    args = dict(itertools.izip(self.field_names, parts))
    return reference_type(**args)

  def testToCamel(self):
    self.assertEqual('lowerCamel', bigquery_client._ToLowerCamel('lower_camel'))

  def testReadSchemaFromFile(self):
    # Test the filename case.
    with tempfile.NamedTemporaryFile() as f:
      # Write out the results.
      print >>f, '['
      print >>f, ' { "name": "Number", "type": "integer", "mode": "REQUIRED" },'
      print >>f, ' { "name": "Name", "type": "string", "mode": "REQUIRED" },'
      print >>f, ' { "name": "Other", "type": "string", "mode": "OPTIONAL" }'
      print >>f, ']'
      f.flush()
      # Read them as JSON.
      f.seek(0)
      result = json.load(f)
      # Compare the results.
      self.assertEqual(result, self.client.ReadSchema(f.name))

  def testReadSchemaFromString(self):
    # Check some cases that should pass.
    self.assertEqual(
        [{'name': 'foo', 'type': 'INTEGER'}],
        bigquery_client.BigqueryClient.ReadSchema('foo:integer'))
    self.assertEqual(
        [{'name': 'foo', 'type': 'INTEGER'},
         {'name': 'bar', 'type': 'STRING'}],
        bigquery_client.BigqueryClient.ReadSchema('foo:integer, bar:string'))
    self.assertEqual(
        [{'name': 'foo', 'type': 'STRING'}],
        bigquery_client.BigqueryClient.ReadSchema('foo'))
    self.assertEqual(
        [{'name': 'foo', 'type': 'STRING'},
         {'name': 'bar', 'type': 'STRING'}],
        bigquery_client.BigqueryClient.ReadSchema('foo,bar'))
    self.assertEqual(
        [{'name': 'foo', 'type': 'INTEGER'},
         {'name': 'bar', 'type': 'STRING'}],
        bigquery_client.BigqueryClient.ReadSchema('foo:integer, bar'))
    # Check some cases that should fail.
    self.assertRaises(bigquery_client.BigquerySchemaError,
                      bigquery_client.BigqueryClient.ReadSchema,
                      '')
    self.assertRaises(bigquery_client.BigquerySchemaError,
                      bigquery_client.BigqueryClient.ReadSchema,
                      'foo,bar:int:baz')
    self.assertRaises(bigquery_client.BigquerySchemaError,
                      bigquery_client.BigqueryClient.ReadSchema,
                      'foo:int,,bar:string')
    self.assertRaises(bigquery_client.BigquerySchemaError,
                      bigquery_client.BigqueryClient.ReadSchema,
                      '../foo/bar/fake_filename')

  def testFormatTableInfo(self):
    formatted_table_info = bigquery_client.BigqueryClient.FormatTableInfo(
        json.loads(_TABLE_INFO))
    self.assertEqual(formatted_table_info['Last modified'], '11 Dec 11:47:14')
    self.assertEqual(formatted_table_info['Total Rows'], '0')
    self.assertEqual(formatted_table_info['Total Bytes'], '0')
    self.assertEqual(formatted_table_info['Time Partitioning'],
                     'DAY (field: ts, expirationMs: 10)')

  def testParseIdentifier(self):
    for identifier, parse in self.parse_tests.iteritems():
      self.assertEquals(parse, bigquery_client.BigqueryClient._ParseIdentifier(
          identifier))

  def testGetReference(self):
    for identifier, parse in self.reference_tests.iteritems():
      reference = self._GetReference(parse)
      self.assertEquals(reference, self.client.GetReference(identifier))

  def testParseDatasetReference(self):
    dataset_parses = dict((k, v) for k, v in self.reference_tests.iteritems()
                          if len(filter(bool, v)) == 2)

    for identifier, parse in dataset_parses.iteritems():
      reference = self._GetReference(parse)
      self.assertEquals(reference, self.client.GetDatasetReference(identifier))

  def testParseProjectReference(self):
    project_parses = dict((k, v) for k, v in self.reference_tests.iteritems()
                          if len(filter(bool, v)) == 1)

    for identifier, parse in project_parses.iteritems():
      reference = self._GetReference(parse)
      self.assertEquals(reference, self.client.GetProjectReference(identifier))

    invalid_projects = [
        'prj:ds', 'example.com:prj:ds', 'ds.', 'ds.tbl', 'prj:ds.tbl']

    for invalid in invalid_projects:
      self.assertRaises(bigquery_client.BigqueryError,
                        self.client.GetProjectReference, invalid)

  # Tests parsing job references from identifier strings with project
  # ID, location, job ID included.
  def testParseJobReference_fullyQualified(self):
    self.assertParsesJobReference('proj:loc.jid', None, None, 'proj', 'loc',
                                  'jid')
    self.assertParsesJobReference('proj:loc.jid', 'default_proj', 'default_loc',
                                  'proj', 'loc', 'jid')
    self.assertParsesJobReference('proj:loc.jid', None, 'default_loc', 'proj',
                                  'loc', 'jid')
    self.assertParsesJobReference('proj:loc.jid', 'default_proj', None, 'proj',
                                  'loc', 'jid')

  # Tests parsing job references from identifier strings with project
  # ID and job ID but no location included.
  def testParseJobReference_noLocation(self):
    self.assertParsesJobReference('proj:jid', None, None, 'proj', None, 'jid')
    self.assertParsesJobReference('proj:jid', 'default_proj', 'default_loc',
                                  'proj', 'default_loc', 'jid')
    self.assertParsesJobReference('proj:jid', None, 'default_loc', 'proj',
                                  'default_loc', 'jid')
    self.assertParsesJobReference('proj:jid', 'default_proj', None, 'proj',
                                  None, 'jid')

  # Tests parsing job references from identifier strings with location
  # and job ID but no project ID included.
  def testParseJobReference_noProject(self):
    self.assertParseJobReferenceRaises('loc.jid', None, None)
    self.assertParsesJobReference('loc.jid', 'default_proj', 'default_loc',
                                  'default_proj', 'loc', 'jid')
    self.assertParseJobReferenceRaises('loc.jid', None, 'default_loc')
    self.assertParsesJobReference('loc.jid', 'default_proj', None,
                                  'default_proj', 'loc', 'jid')

  # Tests parsing job references from identifier strings job ID but no
  # location or project ID included.
  def testParseJobReference_defaultProjectAndLocation(self):
    self.assertParseJobReferenceRaises('jid', None, None)
    self.assertParsesJobReference('jid', 'default_proj', 'default_loc',
                                  'default_proj', 'default_loc', 'jid')
    self.assertParseJobReferenceRaises('jid', None, 'default_loc')
    self.assertParsesJobReference('jid', 'default_proj', None, 'default_proj',
                                  None, 'jid')

  # Regression test for b/74085458.
  def testParseJobReference_locationWithNumber(self):
    identifier = ('google.com:shollyman-bq-experiments:'
                  'asia-northeast1.'
                  'bquijob_583f1593_161e40b3acd')
    self.assertParsesJobReference(identifier,
                                  None,
                                  None,
                                  'google.com:shollyman-bq-experiments',
                                  'asia-northeast1',
                                  'bquijob_583f1593_161e40b3acd')

  # Tests parsing job references from identifier strings with various
  # forms of project IDs.
  def testParseJobReferenceWithLocation(self):
    valid_project_ids = [
        'company-xx-xxx-1',
        'company.com:foo',
        'company.xx:foo',
        'company.com:foo-bar-123',
        'company-division.xx.yy:foo-bar-123',
        'company.division.co:foo-bar-123',
    ]
    for project_id in valid_project_ids:
      location = 'eu'
      job_id = 'some-job-id'
      identifier_with_location = '%s:%s.%s' % (project_id, location, job_id)
      self.assertParsesJobReference(identifier_with_location, None, None,
                                    project_id, location, job_id)
      identifier_without_location = '%s:%s' % (project_id, job_id)
      self.assertParsesJobReference(identifier_without_location, None, None,
                                    project_id, None, job_id)

  def testParseJobReference_projectIdFormats(self):
    project_ids = [
        'company-xx-xxx-1',
        'company.com:foo',
        'company.xx:foo',
        'company.com:foo-bar-123',
        'company-division.xx.yy:foo-bar-123',
        'company.division.co:foo-bar-123',
    ]
    for project_id in project_ids:
      job_id = 'some-job-id'
      job_id_str = '%s:%s' % (project_id, job_id)
      job_reference = self.client.GetJobReference(job_id_str)
      self.assertIsNotNone(job_reference)
      self.assertEqual(project_id, job_reference['projectId'])
      self.assertEqual(job_id, job_reference['jobId'])

    invalid_job_ids = ['prj:', ':job_id', 'prj.loc.jid']
    for invalid in invalid_job_ids:
      self.assertRaises(bigquery_client.BigqueryError,
                        self.client.GetJobReference, invalid)

  def assertParsesJobReference(self, identifier, default_project_id,
                               default_location, expected_project_id,
                               expected_location, expected_job_id):
    self.client.project_id = default_project_id
    job_reference = self.client.GetJobReference(identifier, default_location)
    self.assertIsNotNone(job_reference)
    self.assertEqual(expected_project_id, job_reference['projectId'])
    self.assertEqual(expected_location, job_reference['location'])
    self.assertEqual(expected_job_id, job_reference['jobId'])

  def assertParseJobReferenceRaises(self, identifier, default_project_id,
                                    default_location):
    self.client.project_id = default_project_id
    self.assertRaises(bigquery_client.BigqueryError,
                      self.client.GetJobReference, identifier, default_location)

  def testGetProjectObjectInfo(self):
    # A project that will be matched.
    known_project_id = 'prj_known'
    project = bigquery_client.ApiClientHelper.ProjectReference.Create(
        projectId=known_project_id)

    # A project that will not be matched.
    unknown_project_id = 'prj_unknown'
    unknown_project = bigquery_client.ApiClientHelper.ProjectReference.Create(
        projectId=unknown_project_id)

    # Projects that will be returned by ListProjects().
    projects = [
        {'projectReference': {'projectId': known_project_id}},
        {'projectReference': {'projectId': 'prj_another'}},
        ]

    with mock.patch.object(self.client, 'ListProjects') as list_projects:
      list_projects.return_value = projects

      # A matched project.
      expected = {
          'kind': 'bigquery#project',
          'projectReference': {'projectId': known_project_id},
          }
      self.assertEqual(expected, self.client.GetObjectInfo(project))

      # An unknown project should raise a BigqueryNotFoundError.
      with self.assertRaises(bigquery_client.BigqueryNotFoundError) as cm:
        self.client.GetObjectInfo(unknown_project)
      self.assertEqual(
          'Unknown project %r' % unknown_project_id,
          cm.exception.message)

  def testGetObjectInfoInvalidType(self):
    with self.assertRaises(TypeError):
      self.client.GetObjectInfo('invalid_type')

  def testRaiseError(self):
    # Confirm we handle arbitrary errors gracefully.
    try:
      bigquery_client.BigqueryClient.RaiseError({})
    except bigquery_client.BigqueryError as _:
      pass

  def testJsonToInsertEntry(self):
    result = [
        bigquery_client.JsonToInsertEntry(None, '{"a":1}'),
        bigquery_client.JsonToInsertEntry('key', '{"b":2}'),
        ]
    self.assertEquals([None, 'key'], [x[0] for x in result])
    self.assertEquals(1, result[0][1]['a'])
    self.assertEquals(2, result[1][1]['b'])

    self.assertRaisesRegexp(
        bigquery_client.BigqueryClientError,
        r'Could not parse',
        bigquery_client.JsonToInsertEntry, None, '_junk_')
    self.assertRaisesRegexp(
        bigquery_client.BigqueryClientError,
        r'not a JSON object',
        bigquery_client.JsonToInsertEntry, None, '[1, 2]')

  def testProxy_NoProxy(self):
    http = self.client.GetHttp()
    self.assertEquals(httplib2.proxy_info_from_environment, http.proxy_info)
    self.assertIsNone(None, http.ca_certs)
    self.assertFalse(http.disable_ssl_certificate_validation)

  def testProxy(self):
    FLAGS.proxy_address = 'localhost'
    FLAGS.proxy_port = '8080'
    FLAGS.proxy_username = 'john'
    FLAGS.proxy_password = 'password'
    FLAGS.ca_certificates_file = 'certs.txt'
    FLAGS.disable_ssl_validation = True

    http = self.client.GetHttp()
    self.assertEquals(3, http.proxy_info.proxy_type)
    self.assertEquals('localhost', http.proxy_info.proxy_host)
    self.assertEquals(8080, http.proxy_info.proxy_port)
    self.assertEquals('john', http.proxy_info.proxy_user)
    self.assertEquals('password', http.proxy_info.proxy_pass)
    self.assertEquals('certs.txt', http.ca_certs)
    self.assertTrue(http.disable_ssl_certificate_validation)

if __name__ == '__main__':
  googletest.main()
