#!/usr/bin/env python

"""
Outputs the number of Matterhorn jobs with 'QUEUED' status. See --help for options.
e.g., ./queued_job_count.py -u foo -p bar http://matterhorn.example.edu
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
        running_ops.extend(filter(
            lambda x: x.state in ["RUNNING","WAITING"],
            wf.operations
        ))

    # filter for the operation types we're interested in
    if args.type is not None:
        running_ops = filter(lambda x: x.id in args.type, running_ops)

    # now get any queued child jobs of those operations
    queued_jobs = []
    for op in running_ops:
        queued_jobs.extend(filter(lambda x: x.status == "QUEUED", op.job.children))

    print len(queued_jobs)

if __name__ == '__main__':

    parser = ArgumentParser()
    parser.add_argument('host', help='Matterhorn host (including scheme)')
    parser.add_argument('-u','--username', help='Matterhorn system user')
    parser.add_argument('-p','--password', help='Matterhorn system user password')
    parser.add_argument('-t','--type', action='append',
                        help="Operation types to care about",
                        default=['editor','compose','inspect','video-segment'])

    args = parser.parse_args()
    main(args)
