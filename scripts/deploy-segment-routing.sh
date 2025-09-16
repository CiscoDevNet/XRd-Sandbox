xr-compose \
  --input-file ~/sandbox/topologies/segment-routing/docker-compose.xr.yml \
  --output-file ~/sandbox/topologies/segment-routing/docker-compose.yml \
  --image xrd-control-plane:latest-24.4

sed -i.bak 's/linux:xr-120/linux:eth0/g' ~/sandbox/topologies/segment-routing/docker-compose.yml

docker compose --file ~/sandbox/topologies/segment-routing/docker-compose.yml up --detach
