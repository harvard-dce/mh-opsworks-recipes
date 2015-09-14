#!/bin/bash

namespace="AWS/OpsworksCustom"
# ec2metadata is installed by the aws cloud-init process. Hopefully
# it doesn't change name or functionality any time soon.
# This will have problems when deployed to availability zones
# that don't match their region plus another character.

# availability=$(ec2metadata --availability-zone)
# actual_region=${availability:0:${#availability} -1}

# All opsworks metrics go to us-east-1, no matter what region
# instances live in. Force this region for all metrics and alarms
region="us-east-1"
