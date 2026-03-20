# XRd Sandbox

- [XRd Sandbox](#xrd-sandbox)
  - [Introduction](#introduction)
  - [Access Details](#access-details)
  - [Lab](#lab)
    - [Docker Driver](#docker-driver)
    - [Host-check](#host-check)
    - [Start the Lab](#start-the-lab)
    - [Prepare the compose file](#prepare-the-compose-file)
    - [Start the XRd containers](#start-the-xrd-containers)
    - [Connect to XRd containers](#connect-to-xrd-containers)
    - [XRd management IP](#xrd-management-ip)
    - [End the XRd topology](#end-the-xrd-topology)
  - [Learn more](#learn-more)
  - [VPN Instructions](https://developer.cisco.com/docs/sandbox/#!getting-started/sandbox-vpn-info)
  - [Help](#help)
  - [Appendix - Changes done on the VM](#appendix---changes-done-on-the-vm)
    - [Docker Pools](#docker-pools)

## Introduction

XRd is a containerized IOS-XR operating system that you can deploy on any kind of on-premises or public cloud infrastructure.

XRd inherits all the programmability aspects, including NETCONF and YANG models, from IOS-XR.

The XRd Sandbox provides an environment where developers and network engineers can explore the programmability options available.

On this Sandbox, you find:

- Ubuntu VM with a Docker image of XRd control plane.
- Sample Sandbox XRd Topology.
- Copy of [xrd-tools GitHub repository.](https://github.com/ios-xr/xrd-tools/tree/main)

At the end of this Sandbox, you learn how to work with XRd in a containerized environment with a working segment routing topology.

> **NOTE:** In the [XRd-Sandbox GitHub repository](https://github.com/CiscoDevNet/XRd-Sandbox/blob/main/docker-compose.xr.yml) you can find the files used to create the sandbox. Additionally, you can review notes on the environment setup, and considerations.


## Access Details
After your lab reservation begins, you will receive software VPN information via email, or by clicking on the I/O tab. 


## Lab

We have prepared one Lab to run a segment routing topology that consists of seven (7) XRd routers. One of the XRd routers functions as a PCE, and another XRd router serves as a vRR. Also, we use two alpine containers as the source and destination hosts.

```bash

               xrd-7(PCE)
               /        \
            xrd-3 --- xrd-4
             / |        | \
src --- xrd-1  |        |  xrd-2 --- dst
             \ |        | /
            xrd-5 --- xrd-6
               \        /
               xrd-8(vRR)
```

The Lab is a copy of the [segment-routing sample topology](https://github.com/ios-xr/xrd-tools/tree/main/samples/xr_compose_topos/segment-routing) from [xrd-tools](https://github.com/ios-xr/xrd-tools) with additional _modifications_ to work on the Sandbox management network.

### Docker Driver

[Docker macvlan](https://docs.docker.com/engine/network/drivers/macvlan/) represents one modification that allows the `XRd` containers to be on the same management network as the host.

```yml
networks:
  mgmt:
    ipam:
      config:
        - subnet: 10.10.20.0/24
          gateway: 10.10.20.254
    driver: macvlan
    driver_opts:
      parent: ens160
```

See full `compose` file on [the XRd-Sandbox Github repository](https://github.com/CiscoDevNet/XRd-Sandbox/blob/main/topologies/segment-routing/docker-compose.xr.yml) or in `~/XRd-Sandbox/topologies/segment-routing/docker-compose.xr.yml` inside the Sandbox.

### Host-check

When working on your own environment, ensure you run `host-check` to verify your host is ready for `XRd`. The host in the Sandbox is already prepared.

```bash
sudo /home/developer/XRd-Sandbox/xrd-tools/scripts/host-check --platform xrd-control-plane --extra-checks docker --extra-checks xr-compose
```

<details>
<summary>OUTPUT</summary>

```bash
developer@ubuntu:~$ sudo /home/developer/XRd-Sandbox/xrd-tools/scripts/host-check --platform xrd-control-plane --extra-checks docker --extra-checks xr-compose
==============================
Platform checks - xrd-control-plane
==============================
 PASS -- CPU architecture (x86_64)
 PASS -- CPU cores (10)
 PASS -- Kernel version (5.15)
 PASS -- Base kernel modules
         Installed module(s): dummy, nf_tables
 INFO -- Cgroups
         Cgroups v2 is in use - this is not supported for production environments.
 PASS -- Inotify max user instances
         64000 - this is expected to be sufficient for 16 XRd instance(s).
 PASS -- Inotify max user watches
         249493 - this is expected to be sufficient for 62 XRd instance(s).
 PASS -- Socket kernel parameters (valid settings)
 PASS -- UDP kernel parameters (valid settings)
 INFO -- Core pattern (core files managed by the host)
 PASS -- ASLR (full randomization)
 WARN -- Linux Security Modules
         AppArmor is enabled. XRd is currently unable to run with the
         default docker profile, but can be run with
         '--security-opt apparmor=unconfined' or equivalent.
         However, some features might not work, such as ZTP.
 PASS -- Kernel module parameters
         Kernel modules loaded with expected parameters.
 PASS -- RAM
         Available RAM is 30.6 GiB.
         This is estimated to be sufficient for 15 XRd instance(s), although memory
         usage depends on the running configuration.
         Note that any swap that may be available is not included.

==============================
Extra checks
==============================

xr-compose checks
-----------------------
 PASS -- docker-compose (version 2.24.0)
 PASS -- PyYAML (installed)
 FAIL -- Bridge iptables
         For xr-compose to be able to use Docker bridges, bridge IP tables must
         be disabled. Note that there may be security considerations associated
         with doing so.
         Bridge IP tables can be disabled by setting the kernel parameters
         net.bridge.bridge-nf-call-iptables and net.bridge.bridge-nf-call-ip6tables
         to 0. These can be modified by adding 'net.bridge.bridge-nf-call-iptables=0'
         and 'net.bridge.bridge-nf-call-ip6tables=0' to /etc/sysctl.conf or in a
         dedicated conf file under /etc/sysctl.d/.
         For a temporary fix, run:
           sysctl -w net.bridge.bridge-nf-call-iptables=0
           sysctl -w net.bridge.bridge-nf-call-ip6tables=0

============================================================================
!! One or more platform checks resulted in a warning, see warnings above !!
----------------------------------------------------------------------------
Extra checks failed: xr-compose
============================================================================
developer@ubuntu:~$
```

</details>

### Start the Lab

> **QUICK START:** If you want to play with XRd right away, you can run the command `make -C ~/XRd-Sandbox deploy-segment-routing` to automatically set up and deploy the segment routing topology in a single command. This will handle all the preparation steps described below.
>
> **WATCHING LOGS:** You can use `make -C ~/XRd-Sandbox follow-segment-routing-logs` to watch the logs of XRd containers. Press `Ctrl+C` to stop watching the logs.

Host Credentials

- Username: `developer`
- Password: `C1sco12345!`

Log in to the host VM.

```bash
ssh developer@10.10.20.15
```

### Prepare the compose file

Explore the `docker-compose.xr.yml` file to become more familiar with how the `XRd` containers are defined.

```bash
cat ~/XRd-Sandbox/topologies/segment-routing/docker-compose.xr.yml
```

Create a `compose` file using the script `xr-compose`. This is the easiest way to work with `XRd` topologies.

```bash
xr-compose \
  --input-file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.xr.yml \
  --output-file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml \
  --image ios-xr/xrd-control-plane:25.3.1
```

> **NOTE:** The Sandbox already has `xr-compose` installed, which is part of the [xrd-tools repository.](https://github.com/ios-xr/xrd-tools)

See the `docker-compose.yml` file created.

```bash
cat ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml
```

For the Sandbox environment, modify the `docker-compose.yml` file created. You should specify the interface (inside the container) that should be mapped to the interface `MgmtEth0/RP0/CPU0/0` in `XRd`.

```bash
sed -i.bak 's/linux:xr-120/linux:eth0/g' ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml
```

The `sed` command creates a backup of `docker-compose.yml` and replaces all occurrences of `linux:xr-120` with `linux:eth0`. `eth0` is the interface `macvlan` creates in the `XRd` container.

See the changes the `sed` command did.

```bash
diff ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml.bak ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml
```

### Start the XRd containers

Bring up the containers and run them in the background.

```bash
docker-compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml up --detach
```

> **NOTE:** After starting the XRd containers with Docker Compose, you may experience temporary slowness on the VM. This slowness will disappear once the XRd containers finish booting up.

`XRd` takes around **4 to 5 minutes** to boot up and start listening `SSH` connections for the sandbox environment.

You can watch `XRd` boot up by running `docker logs <XRD_CONTAINER_NAME> --follow`. Use `ctrl+c` to stop it.

### Connect to XRd containers

XRd Credentials

- Username: `cisco`
- Password: `C1sco12345`

See the containers available.

```bash
docker ps
```

The official ways to connect to `XRd` is using `docker attach` and `SSH` directly to `XRd`. You can still do `docker exec -it <XRD_CONTAINER_NAME> bash` (and then `/pkg/bin/xr_cli.sh`) or the equivalent in other platforms, but it bypasses some security checks.

```bash
docker attach <XRD_CONTAINER_NAME>
```

> **NOTE:** When log in using `docker attach` you must press `enter` to get the `IOS-XR` prompt.

**To exit an attached container** use `ctrl-p`, `ctrl+q` to escape the session. This only works with terminal clients. VSCode's terminal does not support this escape sequence.

> **NOTE:** If the startup config used by XRd does not define credentials, you must use `docker attach <XRD_CONTAINER_NAME>` to create a session, **press Enter**, and it will prompt you for a username and password.

You can restart individual XRd containers.

```bash
docker-compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml stop <XRD_CONTAINER_NAME>
docker-compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml rm -f <XRD_CONTAINER_NAME>
docker-compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml up -d <XRD_CONTAINER_NAME>
```

### XRd management IP

| Hostname | Mgmt IP      |
| -------- | ------------ |
| xrd-1    | 10.10.20.101 |
| xrd-2    | 10.10.20.102 |
| xrd-3    | 10.10.20.103 |
| xrd-4    | 10.10.20.104 |
| xrd-5    | 10.10.20.105 |
| xrd-6    | 10.10.20.106 |
| xrd-7    | 10.10.20.107 |
| xrd-8    | 10.10.20.108 |

To ssh a `XRd` instance, from your computer do.

```bash
ssh cisco@10.10.20.101
```

You can find the credentials set on the `xrd-<ID>-startup.cfg` file. For example, refer to `~/XRd-Sandbox/topologies/segment-routing/xrd-1-startup.cfg`.

### End the XRd topology

To bring down the Lab, do:

```bash
docker-compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml down --volumes
```

> **NOTE:** We remove the volumes in case that you want to test more topologies.

## Bring Your Own AI Assistant to Build a Lab

This Sandbox ships with **AI agent skills** that teach an IDE coding assistant how to design, launch, and interact with XRd labs. Instead of following step-by-step instructions, you can describe the network you want in plain language and let the agent build it for you.

### What the Skills Provide

The `xrd-tools/skills/` directory contains two skills:

| Skill | Purpose |
|-------|---------|
| **xr-lab-assistant** | Designs lab topologies, writes IOS-XR router configs, launches labs, and runs post-launch validation |
| **xr-compose-tool** | Wraps `xr-compose` and `docker-compose` behind a managed workflow with session tracking and resource awareness |

A third skill, **`devnet-vm-infra`**, lives at the **project root** (not under `xrd-tools/`) and documents environment workarounds specific to the DevNet XRd Sandbox VM.

Copy the skill directories into the location your IDE assistant uses for skill discovery. The lab skills are under `xrd-tools/skills/`; copy **`devnet-vm-infra`** from the repository root. The target path depends on your IDE—use the commands in **Install the Skills** below.

### Install the Skills

#### Cursor

```bash
mkdir -p ~/XRd-Sandbox/.cursor/skills
cp -r ~/XRd-Sandbox/xrd-tools/skills/xr-lab-assistant ~/XRd-Sandbox/.cursor/skills/
cp -r ~/XRd-Sandbox/xrd-tools/skills/xr-compose-tool  ~/XRd-Sandbox/.cursor/skills/
cp -r ~/XRd-Sandbox/devnet-vm-infra                   ~/XRd-Sandbox/.cursor/skills/
```

#### Windsurf

```bash
mkdir -p ~/XRd-Sandbox/.windsurf/skills
cp -r ~/XRd-Sandbox/xrd-tools/skills/xr-lab-assistant ~/XRd-Sandbox/.windsurf/skills/
cp -r ~/XRd-Sandbox/xrd-tools/skills/xr-compose-tool  ~/XRd-Sandbox/.windsurf/skills/
cp -r ~/XRd-Sandbox/devnet-vm-infra                   ~/XRd-Sandbox/.windsurf/skills/
```

#### GitHub Copilot (VS Code)

```bash
mkdir -p ~/XRd-Sandbox/.github/skills
cp -r ~/XRd-Sandbox/xrd-tools/skills/xr-lab-assistant ~/XRd-Sandbox/.github/skills/
cp -r ~/XRd-Sandbox/xrd-tools/skills/xr-compose-tool  ~/XRd-Sandbox/.github/skills/
cp -r ~/XRd-Sandbox/devnet-vm-infra                   ~/XRd-Sandbox/.github/skills/
```

> **NOTE:** The Sandbox VM has a few environment quirks that the agent will need to work around when launching labs. The `devnet-vm-infra` skill (copied from the project root above) documents these workarounds so the agent can handle them automatically.

### Example: Ask Your Agent to Build a Lab

Once the skills are installed, open the project in your IDE and start a conversation with the agent. Here is an example prompt:

> _"Build a four-router OSPF lab with Area 0 in the core and two stub areas. Verify the OSPF database shows inter-area routes and all loopbacks are reachable."_

The agent will:

1. **Design the topology** -- create a `docker-compose.xr.yml` with routers, L2 links, and macvlan management (following the `devnet-vm-infra` skill on this VM).
2. **Write router configs** -- one IOS-XR startup config per router (interfaces, loopbacks, `router ospf`, areas, and stub settings).
3. **Launch the lab** -- generate `docker-compose.yml` with `xr-compose` and start containers.
4. **Validate convergence** -- wait for boot, confirm OSPF neighbors are **FULL**, inspect the OSPF database for inter-area summaries, and test loopback reachability (e.g. ping).

You can iterate from there: ask it to add new nodes, change policies, or explain what a particular 
`show` command output means.

You can also start a fresh conversation and describe a completely different lab from scratch -- the agent will design, configure, launch, and validate it the same way. Each new prompt can target a different protocol, topology size, or scenario without any dependency on previous sessions.

The agent will typically add new labs under `topologies/<lab_name>/`.

## Learn more

Look at the [xrdocs tutorials](https://xrdocs.io/virtual-routing/tutorials/) which explain in detail all the _in-and-outs_ of XRd.

You can find additional Labs on `~/xrd-tools/samples/xr_compose_topos` in the Sandbox. These Labs are part of the [xrd-tools GitHub repository,](https://github.com/ios-xr/xrd-tools/) so direct `SSH` will not work out of the box. You can use the host VM as jump host or adapt the topologies following the lessons provided here.

Checkout our [IOS-XR Dev Center](https://developer.cisco.com/site/ios-xr/) on DevNet to find more material around `IOS-XR` programmability.

## Help

For _questions_ about `XRd` itself go to the [Network Devices community.](https://community.cisco.com/t5/network-devices/bd-p/disc-dev-network-devices)

For _issues_ with the Sandbox, first, release your current reservation and initiate a new one. If the issues persist, contact the Sandbox team [on the Sandbox community space.](https://communities.cisco.com/community/developer/sandbox)

## Appendix - Changes done on the VM

### Docker Pools

We set up default address pools to avoid overlapping with networks used by the Sandbox, which caused traffic blackholes.

```bash
developer@ubuntu:~$ cat /etc/docker/daemon.json
{
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    }
  ]
}
developer@ubuntu:~$
```

### Allow host-check to run with sudo without password

To allow the users to run `host-check` with `sudo` without password, we created a file `/etc/sudoers.d/developer-hostcheck` with the following content.

```bash
root@xrd-base:/etc/sudoers.d# cat developer-hostcheck
developer ALL=(ALL) NOPASSWD: /home/developer/XRd-Sandbox/xrd-tools/scripts/host-check
root@xrd-base:/etc/sudoers.d# pwd
/etc/sudoers.d
```