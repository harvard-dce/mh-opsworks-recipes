#!/usr/bin/env python

"""
Outputs the number of Opencast jobs with 'QUEUED' status. See --help for options.
e.g., ./queued_job_count.py -u foo -p bar http://opencast.example.edu
"""

import six
import syslog
import requests
from requests.auth import HTTPDigestAuth
import xml.etree.ElementTree as ET
from argparse import ArgumentParser

if six.PY3:
    from urllib.parse import urljoin
else:
    from urlparse import urljoin


class JobLoadCalculator(object):

    def __init__(self, parsed_args):
        self.worker_hosts = ['http://' + x for x in parsed_args.worker_dns_names]
        self.digest_auth = HTTPDigestAuth(parsed_args.username, parsed_args.password)
        self.http_headers = {'X-REQUESTED-AUTH': 'Digest'}
        self.xml_ns = {'oc': 'http://serviceregistry.opencastproject.org'}
        self.admin_host = 'http://' + args.admin_host

    def percent_used(self):

        syslog.syslog("Calculating percent job_load usage")
        syslog.syslog("{} workers running".format(len(self.worker_hosts)))

        if not len(self.worker_hosts):
            print("0")

        max_loads = self.load_factors('services/maxload')
        current_loads = self.load_factors('services/currentload')

        max_load = sum(max_loads.values())
        current_load = sum(current_loads.values())

        job_load_pct = round( (current_load / max_load) * 100, 2)
        syslog.syslog("current: {}, max: {}, pct: {}".format(current_load, max_load, job_load_pct))
        print(job_load_pct)

    def max_available(self):

        syslog.syslog("Determining max available load on any given worker")
        syslog.syslog("{} workers running".format(len(self.worker_hosts)))

        if not len(self.worker_hosts):
            print("0.0")

        max_loads = self.load_factors('services/maxload')
        current_loads = self.load_factors('services/currentload')

        # get a tuple of each host's max/current load
        available_loads = {
            x: max_loads[x] - current_loads[x] for x in max_loads.keys()
        }
        syslog.syslog("available loads: {}".format(available_loads))

        # sort by the difference descending and take the first one
        max_v_current_sorted = sorted(available_loads.values(), reverse=True)[0]
        syslog.syslog("Max available job_load: {}".format(max_v_current_sorted))
        print(max_v_current_sorted)

    def running_workflows(self):

        syslog.syslog("Fetching count of running workflows")
        endpoint_url = urljoin(self.admin_host, 'admin-ng/job/tasks.json')
        params = {'limit': 999, 'status': 'RUNNING'}
        resp = requests.get(endpoint_url, params=params, auth=self.digest_auth, headers=self.http_headers)
        tasks = resp.json()
        syslog.syslog("Running workflows: {}".format(tasks['count']))
        print(tasks['count'])


    def load_factors(self, endpoint):
        endpoint_url = urljoin(self.admin_host, endpoint)
        resp = requests.get(endpoint_url, auth=self.digest_auth, headers=self.http_headers)
        xml_root = ET.fromstring(resp.content)
        nodes = xml_root.findall('.//oc:node', namespaces=self.xml_ns)
        return {
            x.attrib['host']: float(x.attrib['loadFactor']) for x in nodes
            if x.attrib['host'] in self.worker_hosts
        }


if __name__ == '__main__':

    parser = ArgumentParser()
    parser.add_argument('-u','--username', help='Opencast system user')
    parser.add_argument('-p','--password', help='Opencast system user password')
    parser.add_argument('-m','--mode', help='Either "percent_used" or "max_available"')
    parser.add_argument('-a','--admin_host', help='admin host')
    parser.add_argument('worker_dns_names', nargs='*')

    args = parser.parse_args()
    jlc = JobLoadCalculator(args)

    if hasattr(jlc, args.mode):
        getattr(jlc, args.mode)()
    else:
        raise RuntimeError("invalid mode: {}".format(args.mode))
