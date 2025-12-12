# 🔄 IOS XR Always-On Sandbox

## 📖 Overview

The IOS XR Always-On Sandbox provides an environment where developers and network engineers can explore the programmability options available on this routing platform. These include:

- 🧪 **Testing NETCONF/gRPC YANG configurations**
- 📊 **Exploring streaming telemetry capabilities**
- 🔌 **Developing gNMI-based applications**
- 🏗️ **Prototyping network automation scripts**
- 📚 **Learning IOS XR programmability features**

## 🌐 Topology

```plaintext
     xrd-1
    /     \
 xrd-2 -- xrd-3
```

## 🔑 Access

**Credentials:**

Use the credentials provided in your sandbox reservation to connect to the XRd devices. You can find them on the email sent after reservation or in the IO tab on the sandbox environment page.

## 🔌 Available Protocols & Ports

| Protocol | Port  |
| -------- | ----- |
| SSH      | 22    |
| NETCONF  | 830   |
| gNMI     | 57777 |

- **gNMI:** No TLS (lab environment)

## 📊 Node Information

### Management Network

| Node  | Management IP  |
| ----- | -------------- |
| xrd-1 | `10.10.20.101` |
| xrd-2 | `10.10.20.102` |
| xrd-3 | `10.10.20.103` |

**Note:** Do not modify the management IP addresses. You will lose access to the devices.

### 🔌 Point-to-Point Links

| Node A | Interface   | ←→  | Interface   | Node B |
| ------ | ----------- | --- | ----------- | ------ |
| xrd-1  | `Gi0/0/0/0` | ←→  | `Gi0/0/0/0` | xrd-2  |
| xrd-1  | `Gi0/0/0/1` | ←→  | `Gi0/0/0/1` | xrd-3  |
| xrd-2  | `Gi0/0/0/2` | ←→  | `Gi0/0/0/2` | xrd-3  |

IP addresses might change over time as this is a shared environment. Please refer to the "Important: Shared Environment Notice" section below for more details.

## ⚖️ Good Citizen Code of Conduct

This "IOS-XR" Always On Sandbox resource is shared. This means that you can see other developers' and network engineers changes and they can see yours.

**Follow these guidelines:**

- ❌ **Do not erase or change** configuration you have not created yourself.
- ❌ **Do not perform performance testing** against this shared instance.
- ✅ **Use this space to explore, learn & verify** interoperability.
- ✅ **Remove your configuration** after done with testing.

## ⚠️ Important: Shared Environment Notice

**📋 Initial State Reference**

The IP addressing, hostnames, and protocol configurations shown below represent the **initial deployment state** and serve as a reference for getting started. However, since this is a **shared sandbox environment**:

- 🔄 **Configuration may drift over time** as other users make changes
- 🏷️ **IP addresses and hostnames** may be modified by other developers
- ⚙️ **Protocol settings** (OSPF, BGP) may be reconfigured or disabled
- 🚀 **Use initial state as a jumpstart** - not guaranteed to always be available

### 🗃️ Original IP Addressing

Since this is a shared environment, the IP addresses may change over time. Below is the original IP addressing applied at deployment for reference.

| Node  | Router ID | loopback0 IP |
| ----- | --------- | ------------ |
| xrd-1 | `1.1.1.1` | `1.1.1.1/32` |
| xrd-2 | `2.2.2.2` | `2.2.2.2/32` |
| xrd-3 | `3.3.3.3` | `3.3.3.3/32` |

### 🔌 Addresses on Point-to-Point Links

| Node A | Interface   | IP Address | ←→  | IP Address | Interface   | Node B | Subnet        |
| ------ | ----------- | ---------- | --- | ---------- | ----------- | ------ | ------------- |
| xrd-1  | `Gi0/0/0/0` | `10.1.2.1` | ←→  | `10.1.2.2` | `Gi0/0/0/0` | xrd-2  | `10.1.2.0/24` |
| xrd-1  | `Gi0/0/0/1` | `10.1.3.1` | ←→  | `10.1.3.3` | `Gi0/0/0/1` | xrd-3  | `10.1.3.0/24` |
| xrd-2  | `Gi0/0/0/2` | `10.2.3.2` | ←→  | `10.2.3.3` | `Gi0/0/0/2` | xrd-3  | `10.2.3.0/24` |

### 🔧 Protocol Configuration

A basic configuration is pre-applied to each node, including:

- **OSPF**: Enabled on all interfaces
- **BGP**: Peering established with iBGP

If you want to see the original configuration files used during deployment, please refer to the [XRd-Sandbox Repository Always On Topology](https://github.com/CiscoDevNet/XRd-Sandbox/tree/main/topologies/always-on).

## 📚 Learning Resources

There are various examples and documentation to assist with getting started:

### Programming Guides

- 🔗 [Programmability @ XRdocs.io](https://xrdocs.io/programmability/)
- 🔗 [Application hosting @ XRdocs.io](https://xrdocs.io/application-hosting/)
- 🔗 [Model Driven Programmability](https://developer.cisco.com/site/standard-network-devices/)
- 🔗 [IOS-XR over gRPC](https://developer.cisco.com/network-automation/detail/5d6bbd08-7099-11eb-aa41-aa8fea613d8b/)

### Repository

- 🔗 [XRd-Sandbox Repository](https://github.com/CiscoDevNet/XRd-Sandbox) - Explore the configuration files, deployment scripts, and learn how this topology is built

### Support

- 🆘 [Sandbox Support](https://communities.cisco.com/community/developer/sandbox)
