---
name: devnet-vm-infra
description: Documents infrastructure workarounds required on the DevNet XRd Sandbox VM
---

# DevNet VM Infrastructure Workarounds

This VM has **22.6 GiB of RAM** and can support a maximum of **11 XRd
instances** concurrently. Lab topologies must stay within this limit. If
another lab is already running, account for its containers before launching a
new one.

The VM also ships with a Docker daemon and Compose plugin whose versions
conflict in several ways. The workarounds below must be applied before labs
will launch successfully.

## 1. Docker API Version Pinning

**Problem:** Docker Compose v5.1.0 (plugin) defaults to a client API version
newer than the Docker daemon (24.0.5, API 1.43) supports, producing:

```
client version 1.53 is too new. Maximum supported API version is 1.43
```

**Fix:** Export the variable in every shell session that will run Docker
commands:

```bash
export DOCKER_API_VERSION=1.43
```

## 2. Docker Compose v5 Multi-Network Bug

**Problem:** Docker Compose v5 (`docker compose`) fails when creating
containers attached to multiple custom networks, even with the API version
pinned:

```
Container cannot be connected to network endpoints: …
```

**Fix:** Do **not** use the Compose v5 plugin to bring up XRd labs. Instead:

1. Use `xr-compose` to **generate** `docker-compose.yml` (omit the `-l` flag):

   ```bash
   xr-compose -f docker-compose.xr.yml -i <image>
   ```

2. Launch with the standalone `docker-compose` v1.29.2 (already installed via
   pip):

   ```bash
   docker-compose up -d
   ```

> The standalone binary handles multi-network attachment correctly on this
> daemon version.

### `just launch` and `xr-compose -l` (why bring-up fails)

The **xr-compose-tool** recipe `just launch <lab-path>` finishes by running
`xr-compose -f ./docker-compose.xr.yml -i <image> -l` (the **`-l`** = launch flag).

That **launch** flag tells `xr-compose` to start the topology immediately. On this VM that path goes through **Docker Compose v5** (the plugin). The same **multi-network attach** failure then appears for almost every real lab: each XRd router joins **several `xr_l2network` segments plus macvlan `mgmt`**, which triggers:

`Container cannot be connected to network endpoints: …`

So **`just launch` is not a supported way to start multi-network labs on DevNet**, even with `DOCKER_API_VERSION=1.43` exported. The fix is **not** “retry `just launch`” — it is to **avoid `-l`** and use the **generate + `docker-compose up -d`** sequence in the fix above (run from the lab directory that contains `docker-compose.xr.yml`).

**End-to-end example** (repo root = `~/XRd-Sandbox`, lab path = `topologies/ospf_multiarea_stub`):

```bash
export DOCKER_API_VERSION=1.43
export XR_LAB_XRD_IMAGE=ios-xr/xrd-control-plane:25.3.1   # see “XRd image” below
cd ~/XRd-Sandbox/topologies/ospf_multiarea_stub
xr-compose -f docker-compose.xr.yml -i "$XR_LAB_XRD_IMAGE"
# If needed: §5 sed to set linux:eth0 on XR_MGMT_INTERFACES
docker-compose up -d
```

**What you can still use `just` for:** after containers are up, **`just wait-for-boot`**, **`just run`**, and **`just exec`** work as usual. **`just shutdown <lab-path>`** is also safe — it runs **`docker-compose down`** inside the lab directory and does **not** use `xr-compose -l`. Pass the same lab path (relative to `XR_LAB_ROOT`) as for launch.

**Tracking file:** `just launch` writes `.xr-compose-tool/running/<lab-id>.env` under the repo. Manual bring-up skips that file; shutdown from `just` still works for local Docker. If you rely on `just running` to list labs, either adopt manual tracking or treat “containers up + `docker ps`” as source of truth.

### XRd image: `pull access denied` and `:latest`

`xr-compose -l` (and any step that **pulls** the `-i` image) may fail with:

`pull access denied for ios-xr/xrd-control-plane …`

The sandbox VM typically has XRd **pre-loaded under a version tag** (e.g. `25.3.1`), not as a registry pull for `latest`.

1. Inspect tags: `docker images ios-xr/xrd-control-plane`
2. Export the tag you have: `export XR_LAB_XRD_IMAGE=ios-xr/xrd-control-plane:<tag>`

Use that same variable for **`xr-compose -f … -i "$XR_LAB_XRD_IMAGE"`** (no `-l`) so Compose does not try to pull an unreachable `latest` image.

## 3. `just` Command Runner

**Problem:** The `just` command runner is not pre-installed. The
`xr-compose-tool` skill's `just-wrapper.sh` requires it.

**Fix:** Install to `~/bin` (no root needed) and ensure it is on PATH:

```bash
mkdir -p ~/bin
curl -sSfL https://just.systems/install.sh | bash -s -- --to ~/bin
export PATH="$HOME/bin:$PATH"
```

Persist the PATH addition in `~/.bashrc` if desired.

## 4. Docker Network Gateway Conflicts

**Problem:** When a service is assigned a static `ipv4_address` that collides
with Docker's auto-assigned gateway (typically the `.1` address in the
subnet), container creation fails:

```
Cannot start service <name>: Address already in use
```

**Fix:** Explicitly set a non-conflicting `gateway` in the network IPAM
config inside `docker-compose.xr.yml`:

```yaml
networks:
  example-net:
    ipam:
      config:
        - subnet: 10.10.1.0/24
          gateway: 10.10.1.254
    xr_interfaces:
      - router:Gi0/0/0/0
```

Choose a gateway address that does not overlap with any service IP in the
network.

## 5. Macvlan Management Interfaces (Required)

Every lab **must** include a macvlan management network so users can SSH to the
routers from external machines. The host management interface is `ens192` on
subnet `10.10.20.0/24`.

### docker-compose.xr.yml changes

Add a `mgmt` network definition and attach every XRd service to it:

```yaml
networks:
  mgmt:
    xr_interfaces:
      - router1:Mg0/RP0/CPU0/0
      - router2:Mg0/RP0/CPU0/0
    ipam:
      config:
        - subnet: 10.10.20.0/24
          gateway: 10.10.20.254
    driver: macvlan
    driver_opts:
      parent: ens192
```

Each XRd service needs `Mg0/RP0/CPU0/0` with `snoop_v4` and a static IP on
the `mgmt` network:

```yaml
services:
  router1:
    xr_interfaces:
      - Gi0/0/0/0
      - Mg0/RP0/CPU0/0:
          snoop_v4: True
          snoop_v4_default_route: True
    networks:
      mgmt:
        ipv4_address: 10.10.20.110
```

### Post-generation fix

After running `xr-compose` to generate `docker-compose.yml`, replace the
generated management interface name with `eth0` (the interface macvlan
creates inside the container):

```bash
sed -i 's/linux:xr-n[0-9]*,xr_name=Mg0/linux:eth0,xr_name=Mg0/g' docker-compose.yml
```

Or use the editor to replace all occurrences of `linux:xr-n<N>` on
`XR_MGMT_INTERFACES` lines with `linux:eth0`.

### IP address range

Use `10.10.20.110` and above to avoid conflicting with the segment-routing
lab's range (`10.10.20.101–108`). The router configs do not need changes --
`ssh server vrf default` is already configured and the `snoop_v4` flag
handles IP assignment automatically.

### Connectivity note

Macvlan containers are **not** reachable from the host itself -- this is a
known Docker macvlan limitation. The management IPs are reachable from
external machines on the same L2 network (e.g., a laptop connected via the
sandbox VPN). From the host, use `docker attach <container>` instead.

## Quick-Start Checklist

Before launching any lab on this VM, ensure:

- [ ] `DOCKER_API_VERSION=1.43` is exported
- [ ] `~/bin` is on PATH (for `just`)
- [ ] Lab **bring-up** uses **`xr-compose` without `-l`** then **`docker-compose up -d`**
      — do **not** rely on **`just launch`** for multi-network topologies (it uses
      `xr-compose -l` → Compose v5 → attach failure)
- [ ] `XR_LAB_XRD_IMAGE` points at a **local** tag from `docker images`, not an
      unpullable `latest`
- [ ] Labs are launched via standalone `docker-compose` (v1.29.2), not the
      Compose v5 plugin
- [ ] Any network with static service IPs has an explicit `gateway` in its
      IPAM config
- [ ] A macvlan `mgmt` network on `ens192` is included with
      `Mg0/RP0/CPU0/0` (`snoop_v4`) on every XRd service
- [ ] The generated `docker-compose.yml` has `linux:eth0` for management
      interfaces (not the auto-generated `linux:xr-n<N>`)
