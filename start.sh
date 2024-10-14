#!/bin/bash

# Start BIND DNS Server
service bind9 start

# Start dnsdist
dnsdist -C /etc/dnsdist/dnsdist.conf

# Keep the container running
tail -f /dev/null

