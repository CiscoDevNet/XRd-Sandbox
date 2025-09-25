# Sandbox Always-On Topology Deployment Guide

## 🚀 Automated Deployment (Recommended)

The easiest way to deploy this topology is using the Makefile targets:

### Deploy the Topology

```bash
make deploy-always-on
```

### Monitor the Topology

```bash
make follow-always-on-logs
```

### Undeploy the Topology

```bash
make undeploy-always-on
```

## 🔧 Manual Deployment Steps

If you prefer manual deployment or need to troubleshoot:

### Step 1: Generate Docker Compose File

```bash
xr-compose \
  --input-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.xr.yml \
  --output-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  --image ios-xr/xrd-control-plane:25.3.1
```

### Step 2: Update Interface Names

```bash
sed -i.bak 's/linux:xr-30/linux:eth0/g' \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml
```

### Step 3: Deploy the Topology

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  up --detach
```

### Step 4: Monitor Logs

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  logs --follow
```

### 🛑 Stopping the Topology

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  down --volumes --remove-orphans
```
