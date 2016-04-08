#!/bin/bash

# Credits: Inspired by https://github.com/pboos/docker-rancher-cassandra

set -e

touch /tmp/worker_names_tmp

if [ "$RANCHER_ENABLE" = 'true' ]; then

  echo "Discovering shards"

  RANCHER_META=http://rancher-metadata/2015-12-19
  PRIMARY_IP=$(curl --retry 3 --fail --silent $RANCHER_META/self/container/primary_ip)

  PG_SHARD_SERVICE=${PG_SHARD_SERVICE:-$(curl --retry 3 --fail --silent $RANCHER_META/self/service/name)}

  containers="$(curl --retry 3 --fail --silent $RANCHER_META/services/$PG_SHARD_SERVICE/containers)"
  readarray -t containers_array <<<"$containers"
  for i in "${containers_array[@]}"
  do
    container_name="$(echo ${i} | cut -d = -f2)"
    container_ip="$(curl --retry 3 --fail --silent $RANCHER_META/containers/$container_name/primary_ip)"

    echo "Found shard $container_name with IP $container_ip"

    if [ "$PRIMARY_IP" != "$container_ip" ]; then
      echo "$container_ip 5432" >> /tmp/worker_names_tmp
    fi
  done

  cat /tmp/worker_names_tmp | sort | uniq > "$PGDATA/pg_worker_list.conf"
  rm /tmp/worker_names_tmp
fi

if [ "$CITUS_STANDALONE" ]
then
  echo -e "localhost\t5432" >> "$PGDATA/pg_worker_list.conf"
fi
