# 🔄 Always-On Sandbox Topology

## 📖 Overview

The IOS XR Always-On Sandbox provides an environment where developers and network engineers can explore the programmability options available on this routing platform. These include:

- **Model Driven Programmability** with YANG Data Models and NETCONF
- **Streaming Telemetry**
- **Service-Layer APIs**
- **Application Hosting**

## 🌐 Topology Overview

```plaintext
     xrd-1
    /     \
 xrd-2 -- xrd-3
```

## 📊 Node Information

### Management Network

| Node  | Management IP  | Router ID |
| ----- | -------------- | --------- |
| xrd-1 | `10.10.20.101` | `1.1.1.1` |
| xrd-2 | `10.10.20.102` | `2.2.2.2` |
| xrd-3 | `10.10.20.103` | `3.3.3.3` |

### 🔌 Interface Connections

| Node 1 Interface  | Node 2 Interface  | Subnet        |
| ----------------- | ----------------- | ------------- |
| xrd-1 `Gi0/0/0/0` | xrd-2 `Gi0/0/0/0` | `10.1.2.0/24` |
| xrd-2 `Gi0/0/0/2` | xrd-3 `Gi0/0/0/2` | `10.2.3.0/24` |
| xrd-1 `Gi0/0/0/1` | xrd-3 `Gi0/0/0/1` | `10.1.3.0/24` |

### 🏷️ Interface IP Addresses

**xrd-1:**

- `Lo0`: `1.1.1.1/32`
- `Gi0/0/0/0`: `10.1.2.1/24` (to xrd-2)
- `Gi0/0/0/1`: `10.1.3.1/24` (to xrd-3)

**xrd-2:**

- `Lo0`: `2.2.2.2/32`
- `Gi0/0/0/0`: `10.1.2.2/24` (to xrd-1)
- `Gi0/0/0/2`: `10.2.3.2/24` (to xrd-3)

**xrd-3:**

- `Lo0`: `3.3.3.3/32`
- `Gi0/0/0/1`: `10.1.3.3/24` (to xrd-1)
- `Gi0/0/0/2`: `10.2.3.3/24` (to xrd-2)

## ⚠️ Important: Shared Environment Notice

**📋 Initial State Reference**

The IP addressing, hostnames, and protocol configurations shown above represent the **initial deployment state** and serve as a reference for getting started. However, since this is a **shared sandbox environment**:

- 🔄 **Configuration may drift over time** as other users make changes
- 🏷️ **IP addresses and hostnames** may be modified by other developers
- ⚙️ **Protocol settings** (OSPF, BGP) may be reconfigured or disabled
- 🚀 **Use initial state as a jumpstart** - not guaranteed to always be available

**🔗 What Remains Constant**

The following elements are permanent and will always be available:

**Physical Link Connections:**

- ✅ `xrd-1 Gi0/0/0/0` ↔ `xrd-2 Gi0/0/0/0`
- ✅ `xrd-1 Gi0/0/0/1` ↔ `xrd-3 Gi0/0/0/1`
- ✅ `xrd-2 Gi0/0/0/2` ↔ `xrd-3 Gi0/0/0/2`

**Access Credentials:**

- ✅ Username: `cisco` / Password: `C1sco12345`

💡 **Recommendation:** Always verify current configuration when connecting to the sandbox and be prepared to adapt to the existing state.

## 🔧 Protocol Configuration

A basic configuration is pre-applied to each node, including:

- **OSPF**: Enabled on all interfaces
- **BGP**: Peering established with iBGP

## 🔑 Access Information

**Credentials:**

- Username: `cisco`
- Password: `C1sco12345`

## 🔌 Available Protocols & Ports

| Protocol | Port  | Transport |
| -------- | ----- | --------- |
| SSH      | 22    | TCP/SSH   |
| NETCONF  | 830   | SSH       |
| gNMI     | 57777 | gRPC      |

- **gNMI:** No TLS (lab environment)

## ⚖️ Good Citizen Code of Conduct

This "IOS-XR" Always On Sandbox resource is shared. This means that you can see other developers' and network engineers changes and they can see yours.

**Please follow these guidelines:**

- ❌ **Do not erase or change** configuration you have not created yourself.
- ❌ **Do not perform performance testing** against this shared instance.
- ✅ **Use this space to explore, learn & verify** interoperability.

## 📚 Learning Resources

There are various examples and documentation to assist with getting started:

### Programming Guides

- 🔗 [Programmability @ XRdocs.io](https://xrdocs.io/programmability/)
- 🔗 [Application hosting @ XRdocs.io](https://xrdocs.io/application-hosting/)
- 🔗 [Model Driven Programmability](https://developer.cisco.com/site/standard-network-devices/)
- 🔗 [IOS-XR over gRPC](https://developer.cisco.com/network-automation/detail/5d6bbd08-7099-11eb-aa41-aa8fea613d8b/)

### Support

- 🆘 [Sandbox Support](https://communities.cisco.com/community/developer/sandbox)

## 🎯 Use Cases

This sandbox is perfect for:

- 🧪 **Testing NETCONF/YANG configurations**
- 📊 **Exploring streaming telemetry capabilities**
- 🔌 **Developing gNMI-based applications**
- 🏗️ **Prototyping network automation scripts**
- 📚 **Learning IOS XR programmability features**
