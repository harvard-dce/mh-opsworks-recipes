#!/usr/bin/env python

"""
Outputs the number of Opencast jobs with 'QUEUED' status. See --help for options.
e.g., ./queued_job_count.py -u foo -p bar http://opencast.example.edu
"""

from pyhorn import MHClient
from argparse import ArgumentParser

def main(args):

    mh = MHClient(args.host, args.username, args.password)

    # get the running workflows; high "count" value to make sure we get all
    running_wfs = mh.workflows(state="RUNNING", count=1000)

    # then get their running operations
    running_ops = []
    for wf in running_wfs:
        running_ops.extend([
            x for x in wf.operations
            if x.state in ["RUNNING", "WAITING"]
        ])

    # filter for the operation types we're interested in
    if args.type:
        running_ops = [x for x in running_ops if x.id in args.type]

    # now get any queued child jobs of those operations
    queued_jobs = []
    for op in running_ops:
        queued_jobs.extend([
            x for x in op.job.children
            if x.status == 'QUEUED'
        ])

    print len(queued_jobs)

if __name__ == '__main__':

    parser = ArgumentParser()
    parser.add_argument('host', help='Opencast host (including scheme)')
    parser.add_argument('-u','--username', help='Opencast system user')
    parser.add_argument('-p','--password', help='Opencast system user password')
    parser.add_argument('-t','--type', action='append', help="Operation types to care about")

    args = parser.parse_args()
    main(args)
