- [🔄 IOS XR Always-On Sandbox](#-ios-xr-always-on-sandbox)
  - [🎯 What You Can Do](#-what-you-can-do)
  - [🌐 Topology](#-topology)
  - [🔑 Getting Access](#-getting-access)
  - [📊 Connection Information](#-connection-information)
  - [⚖️ Shared Environment Guidelines](#️-shared-environment-guidelines)
  - [🔧 Programmatic Access Examples](#-programmatic-access-examples)
  - [⚠️ Configuration State Notice](#️-configuration-state-notice)
  - [⚠️ Known Limitations](#️-known-limitations)
  - [📚 Learning Resources](#-learning-resources)
  - [❓ Frequently Asked Questions](#-frequently-asked-questions)
  - [🆘 Support](#-support)

# 🔄 IOS XR Always-On Sandbox

Welcome to the IOS XR Always-On Sandbox! This shared environment allows developers and network engineers to explore the programmability features of the IOS XR routing platform.

## 🎯 What You Can Do

- 🧪 Test NETCONF/gRPC YANG configurations
- 📊 Explore streaming telemetry capabilities
- 🔌 Develop gNMI-based applications
- 🏗️ Prototype network automation scripts
- 📚 Learn IOS XR programmability features

[See these instructions on Github](https://github.com/CiscoDevNet/XRd-Sandbox/tree/main/topologies/always-on/sandbox-instructions.md)

## 🌐 Topology

```plaintext
     xrd-1
    /     \
 xrd-2 -- xrd-3
```

## 🔑 Getting Access

**Important:** Static usernames and passwords are no longer provided. Each user receives unique, time-limited credentials.

### How to Create a Reservation

1. **Launch** - Click the "Launch" button on the IOS XR Programmability AlwaysOn tile
2. **Set Duration** - Select how long you need the sandbox (your credentials will be valid for this period) and click "Review Summary"
3. **Confirm** - Click "Launch Environment" again to start provisioning
4. **Wait** - The sandbox will begin spinning up (takes 1-2 minutes)
5. **Get Credentials** - Once active, your unique credentials appear in the **I/O** tab under **Quick Access**

> **Note:** A new unique password is generated each time you create a reservation.

## 📊 Connection Information

### Nodes & Ports

| Node  | Hostname                    | SSH   | NETCONF | gNMI  |
| ----- | --------------------------- | ----- | ------- | ----- |
| xrd-1 | `sandbox-iosxr-1.cisco.com` | 10022 | 10830   | 10777 |
| xrd-2 | `sandbox-iosxr-2.cisco.com` | 20022 | 20830   | 20777 |
| xrd-3 | `sandbox-iosxr-3.cisco.com` | 30022 | 30830   | 30777 |

**Example SSH connection:**

```bash
ssh -p 10022 <your-username>@sandbox-iosxr-1.cisco.com
```

> ⚠️ **Warning:** Do not modify the management IP address or you will lose access to the instances and the sandbox will have to be reset.

### Physical Topology Links

| Node A | Interface   | ←→  | Interface   | Node B |
| ------ | ----------- | --- | ----------- | ------ |
| xrd-1  | `Gi0/0/0/0` | ←→  | `Gi0/0/0/0` | xrd-2  |
| xrd-1  | `Gi0/0/0/1` | ←→  | `Gi0/0/0/1` | xrd-3  |
| xrd-2  | `Gi0/0/0/2` | ←→  | `Gi0/0/0/2` | xrd-3  |

## ⚖️ Shared Environment Guidelines

**This is a shared sandbox** - multiple users can access it simultaneously. You may see other users' configurations, and they can see yours.

### Best Practices

- ✅ **DO** explore, learn, and test your configurations
- ✅ **DO** remove your configuration when finished
- ✅ **DO** verify interoperability and functionality
- ❌ **DO NOT** modify or delete others' configurations
- ❌ **DO NOT** perform performance or load testing
- ❌ **DO NOT** make changes to base system configurations (tacacs, aaa, mgmt IPs)

> 💡 **Need a dedicated environment?** If you require an isolated sandbox for extended testing or development, use the dedicated **XRd Sandbox** at [devnetsandbox.cisco.com](https://devnetsandbox.cisco.com/)

## 🔧 Programmatic Access Examples

Once you have your credentials from the **I/O** tab, you can use them to test programmatic interfaces like `NETCONF` and `gNMI`.

### NETCONF Example with ncclient

Requires `uv` [see the docs.](https://docs.astral.sh/uv/)

```python
uv run --with ncclient python -c "
from ncclient import manager
with manager.connect(
    host='sandbox-iosxr-1.cisco.com',
    port=10830,
    username='<your-username>',
    password='<your-password>',
    hostkey_verify=False,
    device_params={'name': 'iosxr'}
) as session:
    config = session.get_config(source='running')
    print(config)
"
```

### gNMI Examples with gnmic

**Get interface configuration using JSON encoding:**

Requires `gnmic` [see the docs.](https://gnmic.openconfig.net/)

```bash
gnmic \
  --address sandbox-iosxr-1.cisco.com:10777 \
  --username <your-username> \
  --password <your-password> \
  --encoding JSON_IETF \
  --insecure \
  get --path "openconfig-interfaces:interfaces"
```

**Get operational data using ASCII encoding:**

```bash
gnmic \
  --address sandbox-iosxr-1.cisco.com:10777 \
  --username <your-username> \
  --password <your-password> \
  --encoding ascii \
  --insecure \
  get --path "show version"
```

> **Note:** Replace `<your-username>` and `<your-password>` with the credentials provided in the **I/O** tab of your active reservation.

## ⚠️ Configuration State Notice

### Initial State Reference

The configurations below represent the **intended initial deployment state**. However, because this is a **shared environment**:

- 🔄 Configuration may drift over time as other users make changes
- 🏷️ IP addresses and hostnames may be modified
- ⚙️ Protocol settings (OSPF, BGP) may be reconfigured or disabled
- 🚀 Use this as a reference point. These configurations **are not enforced.**

> **Tip:** Always verify the current configuration state when you connect, as it may differ from the initial state shown below.

### Original IP Addressing

The table below shows the initial IP addressing. These values may change over time.

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

- **OSPF**: Enabled on all interfaces.
- **BGP**: Peering established with iBGP.

If you want to see the original configuration files used during deployment, please refer to the [XRd-Sandbox Repository Always On Topology](https://github.com/CiscoDevNet/XRd-Sandbox/tree/main/topologies/always-on).

## ⚠️ Known Limitations

Please be aware of the following technical limitations:

### Unsupported Features

- Multipoint L2VPN
- VLAN rewrites

### Performance Constraints

This sandbox uses the **control plane version of XRd**, which is:

- ✅ Ideal for testing configurations and programmability
- ❌ Not designed for high-throughput data plane testing

## 📚 Learning Resources

### Documentation & Guides

- [Programmability @ XRdocs.io](https://xrdocs.io/programmability/)
- [Application Hosting @ XRdocs.io](https://xrdocs.io/application-hosting/)
- [Model-Driven Programmability](https://developer.cisco.com/site/standard-network-devices/)
- [IOS-XR over gRPC](https://developer.cisco.com/network-automation/detail/5d6bbd08-7099-11eb-aa41-aa8fea613d8b/)

### Source Repository

Explore configuration files, deployment scripts, and learn how this topology is built:

- [XRd-Sandbox GitHub Repository](https://github.com/CiscoDevNet/XRd-Sandbox)
- [Always-On Topology Files](https://github.com/CiscoDevNet/XRd-Sandbox/tree/main/topologies/always-on)

---

## ❓ Frequently Asked Questions

### Access & Credentials

**Q: Where do I find my username and password?**

A: After creating a reservation, your unique credentials appear in the **I/O** tab of the sandbox portal. There are no static credentials.

**Q: How long do my credentials last?**

A: Credentials are valid for the duration you selected when creating your reservation.

**Q: Can I extend my reservation?**

A: Click the extend button at the top right corner of the environment page. If your reservation expires, you'll need to create a new one with new credentials.

### Configuration & Usage

**Q: The configuration doesn't match what's documented. Why?**

A: This is a shared sandbox environment. Other users may have modified the configuration since deployment. Always verify the current state when connecting.

**Q: Can I save my work between sessions?**

A: Configuration changes persist in the shared environment, but remember to follow best practices and clean up after testing. Save your scripts and configs locally for future reference. The sandbox eventually resets to the initial state.

**Q: What happens if I break something?**

A: The environment is periodically reset to initial state. However, be respectful of other users and avoid making destructive changes.

### Connectivity Issues

**Q: I can't connect via SSH/NETCONF/gNMI. What should I check?**

A: Verify:

1. You're using the correct credentials from the I/O tab
2. Your reservation is still active
3. You're using the correct hostname and port
4. Your network allows outbound connections on the required ports

**Q: I lost access after making configuration changes. Help!**

A: You may have modified the management interface IP address. Create a post in the [Sandbox Community](https://communities.cisco.com/community/developer/sandbox).

### Technical Questions

**Q: Can I use this for production testing?**

A: No. This is a shared development/learning environment. Do not use it for production workloads or sensitive data.

**Q: Why is throughput so low?**

A: This sandbox uses XRd Control Plane, which is optimized for control plane operations and programmability testing, not data plane performance.

**Q: Can I test [specific feature]?**

A: Check the [Known Limitations](#️-known-limitations) section. If your feature isn't listed as unsupported, you can test it. Verify in the IOS XR documentation that it's supported on XRd.

---

## 🆘 Support

Need help? Visit the [DevNet Sandbox Community](https://communities.cisco.com/community/developer/sandbox) for assistance.
