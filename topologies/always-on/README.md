# 🔄 Always-On Topology

## 📖 Overview

This topology demonstrates a simple 3-node XRd network suitable for exploring IOS XR programmability features. Use this as a reference for deploying your own environment.

For sandbox platform instructions, see [sandbox-instructions.md](./sandbox-instructions.md).

## 🌐 Topology

```plaintext
     xrd-1
    /     \
 xrd-2 -- xrd-3
```

## 🔌 Enabled Services

| Protocol | Port  | Transport |
| -------- | ----- | --------- |
| SSH      | 22    | TCP/SSH   |
| NETCONF  | 830   | SSH       |
| gNMI     | 57777 | gRPC      |

## 🔑 Default Credentials

- Username: `cisco`
- Password: `C1sco12345`

## 📊 Node Information

### Management Network

| Node  | Management IP  | Router ID |
| ----- | -------------- | --------- |
| xrd-1 | `10.10.20.101` | `1.1.1.1` |
| xrd-2 | `10.10.20.102` | `2.2.2.2` |
| xrd-3 | `10.10.20.103` | `3.3.3.3` |

### 🔌 Network Interfaces

| Node  | Interface   | IP Address    | To    | Remote Interface | Remote IP     | Subnet        |
| ----- | ----------- | ------------- | ----- | ---------------- | ------------- | ------------- |
| xrd-1 | `Lo0`       | `1.1.1.1/32`  | -     | -                | -             | -             |
| xrd-1 | `Gi0/0/0/0` | `10.1.2.1/24` | xrd-2 | `Gi0/0/0/0`      | `10.1.2.2/24` | `10.1.2.0/24` |
| xrd-1 | `Gi0/0/0/1` | `10.1.3.1/24` | xrd-3 | `Gi0/0/0/1`      | `10.1.3.3/24` | `10.1.3.0/24` |
| xrd-2 | `Lo0`       | `2.2.2.2/32`  | -     | -                | -             | -             |
| xrd-2 | `Gi0/0/0/0` | `10.1.2.2/24` | xrd-1 | `Gi0/0/0/0`      | `10.1.2.1/24` | `10.1.2.0/24` |
| xrd-2 | `Gi0/0/0/2` | `10.2.3.2/24` | xrd-3 | `Gi0/0/0/2`      | `10.2.3.3/24` | `10.2.3.0/24` |
| xrd-3 | `Lo0`       | `3.3.3.3/32`  | -     | -                | -             | -             |
| xrd-3 | `Gi0/0/0/1` | `10.1.3.3/24` | xrd-1 | `Gi0/0/0/1`      | `10.1.3.1/24` | `10.1.3.0/24` |
| xrd-3 | `Gi0/0/0/2` | `10.2.3.3/24` | xrd-2 | `Gi0/0/0/2`      | `10.2.3.2/24` | `10.2.3.0/24` |

## 🔧 Initial Configuration

Basic configuration applied to each node:

- **OSPF**: Enabled on all interfaces
- **BGP**: iBGP peering between all nodes

## 📚 Learning Resources

### Programming Guides

- 🔗 [Programmability @ XRdocs.io](https://xrdocs.io/programmability/)
- 🔗 [Application hosting @ XRdocs.io](https://xrdocs.io/application-hosting/)
- 🔗 [Model Driven Programmability](https://developer.cisco.com/site/standard-network-devices/)
- 🔗 [IOS-XR over gRPC](https://developer.cisco.com/network-automation/detail/5d6bbd08-7099-11eb-aa41-aa8fea613d8b/)

## 🚀 Deployment

See the [deployment scripts](../../scripts/deployment/always-on/) and configuration files in this directory to deploy the topology in your environment.
