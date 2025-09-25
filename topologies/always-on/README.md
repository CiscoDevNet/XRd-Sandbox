# 🔄 Always-On Sandbox Topology

This directory contains the configuration files and Docker Compose setup for an always-on XRd sandbox topology. The topology consists of three XRd nodes interconnected in a triangular fashion, allowing for continuous operation and testing.

## 🌐 Topology Overview

```plaintext
     xrd-1
    /     \
 xrd-2 -- xrd-3
```

## 📊 Node Information

### Management Network

| Node  | Management IP | Router ID |
| ----- | ------------- | --------- |
| xrd-1 | 10.10.20.101  | 1.1.1.1   |
| xrd-2 | 10.10.20.102  | 2.2.2.2   |
| xrd-3 | 10.10.20.103  | 3.3.3.3   |

### 🔌 Interface Connections

| Node 1 Interface | Node 2 Interface | Subnet      |
| ---------------- | ---------------- | ----------- |
| xrd-1 Gi0/0/0/0  | xrd-2 Gi0/0/0/0  | 10.1.2.0/24 |
| xrd-2 Gi0/0/0/2  | xrd-3 Gi0/0/0/2  | 10.2.3.0/24 |
| xrd-1 Gi0/0/0/1  | xrd-3 Gi0/0/0/1  | 10.1.3.0/24 |

### 🏷️ Interface IP Addresses

**xrd-1:**

- Lo0: 1.1.1.1/32
- Gi0/0/0/0: 10.1.2.1/24 (to xrd-2)
- Gi0/0/0/1: 10.1.3.1/24 (to xrd-3)

**xrd-2:**

- Lo0: 2.2.2.2/32
- Gi0/0/0/0: 10.1.2.2/24 (to xrd-1)
- Gi0/0/0/2: 10.2.3.2/24 (to xrd-3)

**xrd-3:**

- Lo0: 3.3.3.3/32
- Gi0/0/0/1: 10.1.3.3/24 (to xrd-1)
- Gi0/0/0/2: 10.2.3.3/24 (to xrd-2)

## 🔧 Protocol Configuration

A basic configuration is pre-applied to each node, including:

- **OSPF**: Enabled on all interfaces
- **BGP**: Peering established with iBGP

## 🔑 Access Information

**Credentials:**

- Username: `cisco`
- Password: `C1sco12345`

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
