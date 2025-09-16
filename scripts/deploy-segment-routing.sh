xr-compose \
  --input-file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.xr.yml \
  --output-file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml \
  --image xrd-control-plane:latest-24.4

sed -i.bak 's/linux:xr-120/linux:eth0/g' ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml

docker compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml up --detach
