# 🔄 IOS XR Always-On Sandbox

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

We no longer provide static usernames and passwords for general use.

To gain access, launch the sandbox topology in the portal. This will generate unique credentials for each user.

Creating a reservation:

- Hit the Launch button on the IOS XR Programmability AlwaysOn tile
- Select a duration. Your credentials will last this length.
- Hit launch again. The sandbox will bein spinning up.
- New credentials will be created and tested for SSH
- Once Active (1-2 mins), the credetails are displayed in the Quick Access Tab
- A unique password is generated each time a new reservation is made.

## 📊 Node Information

To connect to each node, use the following URLs:

| Node  | URL used to access          |
| ----- | --------------------------- |
| xrd-1 | `sandbox-iosxr-1.cisco.com` |
| xrd-2 | `sandbox-iosxr-2.cisco.com` |
| xrd-3 | `sandbox-iosxr-3.cisco.com` |

**Note:** Do not modify the management IP address. You will lose access to the instances.

🔌 **Protocols**

| Protocol      | Port  |
| ------------- | ----- |
| SSH           | 22    |
| NETCONF       | 830   |
| gNMI (no TLS) | 57777 |

🔌 **Point-to-Point Links**

| Node A | Interface   | ←→  | Interface   | Node B |
| ------ | ----------- | --- | ----------- | ------ |
| xrd-1  | `Gi0/0/0/0` | ←→  | `Gi0/0/0/0` | xrd-2  |
| xrd-1  | `Gi0/0/0/1` | ←→  | `Gi0/0/0/1` | xrd-3  |
| xrd-2  | `Gi0/0/0/2` | ←→  | `Gi0/0/0/2` | xrd-3  |

## ⚖️ Good Citizen Code of Conduct

This IOS-XR Always On Sandbox resource is shared. This means that you can see other developers' and network engineers changes and they can see yours.

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

## Limitations

The following features are not supported by XRd:

- Multipoint L2VPN
- Vlan rewrites

The sandbox uses the control plane version of XRd, which is not intended for high throughput.

## 📚 Learning Resources

There are various examples and documentation to assist with getting started:

### Programming Guides

- 🔗 [Programmability @ XRdocs.io](https://xrdocs.io/programmability/)
- 🔗 [Application hosting @ XRdocs.io](https://xrdocs.io/application-hosting/)
- 🔗 [Model Driven Programmability](https://developer.cisco.com/site/standard-network-devices/)
- 🔗 [IOS-XR over gRPC](https://developer.cisco.com/network-automation/detail/5d6bbd08-7099-11eb-aa41-aa8fea613d8b/)

### Repository

🔗 Explore the configuration files, deployment scripts, and learn how this topology is built in the [XRd-Sandbox Repository.](https://github.com/CiscoDevNet/XRd-Sandbox)

## Support

🆘 Go to the [Sandbox community](https://communities.cisco.com/community/developer/sandbox) for support.
