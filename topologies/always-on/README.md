# Always On Sandbox Topology

This directory contains the configuration files and Docker Compose setup for an always-on XRd sandbox topology. The topology consists of three XRd nodes interconnected in a triangular fashion, allowing for continuous operation and testing.

```plaintext
     xrd1
    /    \
 xrd2 -- xrd3
```

### XRd local management IP

| Hostname | Mgmt IP      |
| -------- | ------------ |
| xrd-1    | 10.10.20.101 |
| xrd-2    | 10.10.20.102 |
| xrd-3    | 10.10.20.103 |

### Connect to XRd containers

XRd Credentials

- Username: `cisco`
- Password: `C1sco12345`

# Deploy Manually

```bash
xr-compose \
  --input-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.xr.yml \
  --output-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  --image ios-xr/xrd-control-plane:25.3.1
```

```bash
sed -i.bak 's/linux:xr-30/linux:eth0/g' /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml
```

```bash
docker-compose --file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml up --detach
```

```bash
docker compose --file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml logs -f
```

### End the XRd topology

To bring down the Lab, do:

```bash
docker-compose --file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml down --volumes
```
