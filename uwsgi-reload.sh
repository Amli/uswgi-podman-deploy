#!/bin/env bash

current_container_id="zergling-running"
old_container_id="zergling-previous"
PIDFILE=$1
ZERGPOOL_SOCKET=$2
WORKERS=$3

active_workers_count() {
    local container_id=$1
    echo "$(podman exec -t $container_id uwsgi --connect-and-read /var/run/uwsgi-statsock | jq '[.workers[].pid]  | map(select(. > 0)) | length')"
}

addworker() {
  local container_id=$1
  echo "Requesting a new worker for container $container_id"
  local workers_count="$(active_workers_count $container_id)"

  podman exec $container_id bash -c "echo + > /var/run/master-fifo"

  local new_workers_count=$workers_count

  # wait for spawning
  while [[ "$new_workers_count" -lt "$WORKERS" &&  "$workers_count" -eq "$new_workers_count" ]]; do
    new_workers_count="$(active_workers_count $container_id)"
    sleep 1
  done
}

removeworker() {
  local container_id=$1
  echo "Requesting worker removal for container $container_id"
  local workers_count="$(active_workers_count $container_id)"

  podman exec $container_id bash -c "echo - > /var/run/master-fifo"

  local new_workers_count=$workers_count

  # wait for removal
  while [[ "$new_workers_count" -gt "0" && "$workers_count" -eq "$new_workers_count" ]]; do
    new_workers_count="$(active_workers_count $container_id)"
    sleep 1
  done
}



####################################################################################
# rename running container
####################################################################################

# make sure the old container name does not exist
echo "rename the running container"
podman rm --ignore -v $old_container_id > /dev/null
podman container rename $current_container_id $old_container_id

removeworker $old_container_id

####################################################################################
# start new container with no worker
####################################################################################
echo "start the new container"
podman run -d --conmon-pidfile $PIDFILE --name $current_container_id --cgroups=no-conmon --network host -v $ZERGPOOL_SOCKET:/opt/run/zerg-pool uwsgi-basic:current -p $WORKERS  --cheaper-initial 1 --cheaper 1



####################################################################################
# remove one old worker, add a new, until we reach the expected number
####################################################################################
for i in $(seq 2 $WORKERS); do
  removeworker $old_container_id
  addworker $current_container_id
done


####################################################################################
# stop old container
####################################################################################
echo "stopping old container" $old_container_id
podman stop $old_container_id
echo "deleting old container" $old_container_id
podman rm -v $old_container_id > /dev/null
