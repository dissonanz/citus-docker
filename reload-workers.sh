#!/bin/bash
set -e

touch /tmp/worker_names_tmp

# Update the worker listing on citus master, assumes that the citus are linked
# and have "citus" in their name
# Rancher OS does not update hosts file
curl -s http://rancher-metadata/latest/self/service/links | grep citus | cut -d'/' -f2 | awk '{print $1" 5432"}'>> /tmp/worker_names_tmp

cat /tmp/worker_names_tmp | sort | uniq > "$PGDATA/pg_worker_list.conf"
rm /tmp/worker_names_tmp


if [ "$CITUS_STANDALONE" ]
then
  echo -e "localhost\t5432" >> "$PGDATA/pg_worker_list.conf"
fi
