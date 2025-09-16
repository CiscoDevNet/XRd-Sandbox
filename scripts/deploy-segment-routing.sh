xr-compose \
  --input-file ~/sandbox/docker-compose.xr.yml \
  --output-file ~/sandbox/docker-compose.yml \
  --image xrd-control-plane:latest-24.4

sed -i.bak 's/linux:xr-120/linux:eth0/g' ~/sandbox/docker-compose.yml

docker compose --file ~/sandbox/docker-compose.yml up --detach
