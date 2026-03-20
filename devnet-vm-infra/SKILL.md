---
name: devnet-vm-infra
description: Infrastructure workarounds for the DevNet XRd Sandbox VM (Docker/Compose, mgmt network, launch flow)
---

# DevNet VM Infrastructure Workarounds

**Capacity:** ~22.6 GiB RAM, max **11 XRd instances**. Account for other labs already running.

**Context:** Docker daemon (24.0.5, API 1.43) and Compose plugin v5 conflict. Apply everything below before labs will start reliably.

## Docker API

Compose v5 defaults to API 1.53; daemon max is **1.43**:

```bash
export DOCKER_API_VERSION=1.43
```

## Bring-up: never Compose v5 for multi-network labs

Compose v5 fails attaching containers to multiple custom networks (`Container cannot be connected to network endpoints`). XRd labs use several `xr_l2network` segments plus macvlan `mgmt`, so this hits almost every topology.

**Do not use `just launch` / `xr-compose -l`** — they invoke Compose v5.

**Do:** generate only, then standalone **docker-compose v1.29.2** (pip-installed):

```bash
export DOCKER_API_VERSION=1.43
export XR_LAB_XRD_IMAGE=ios-xr/xrd-control-plane:25.3.1   # use a tag from `docker images`
cd <lab-dir>   # contains docker-compose.xr.yml
xr-compose -f docker-compose.xr.yml -i "$XR_LAB_XRD_IMAGE"
# if using macvlan mgmt: run the sed under “Macvlan management” below
docker-compose up -d
```

**After bring-up:** `just wait-for-boot`, `just run`, `just exec`, and `just shutdown <lab-path>` are fine. Shutdown uses `docker-compose down`, not `-l`. Manual bring-up skips `.xr-compose-tool/running/*.env`; use `docker ps` if you need ground truth.

### Image pull errors

If pull fails for `ios-xr/xrd-control-plane`, the image is usually **local with a version tag**, not `latest`:

```bash
docker images ios-xr/xrd-control-plane
export XR_LAB_XRD_IMAGE=ios-xr/xrd-control-plane:<tag>
```

## `just` binary

Not pre-installed; `xr-compose-tool` expects it:

```bash
mkdir -p ~/bin
curl -sSfL https://just.systems/install.sh | bash -s -- --to ~/bin
export PATH="$HOME/bin:$PATH"   # persist in ~/.bashrc if you want
```

## Static IP vs default gateway

If a service `ipv4_address` collides with Docker’s auto gateway (often `.1`), you get `Address already in use`. Set an explicit **gateway** in that network’s IPAM (e.g. use `.254` and avoid overlapping service IPs):

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

## Macvlan management (`mgmt`)

Required for SSH from outside the host. Host iface **`ens192`**, subnet **`10.10.20.0/24`**. Add macvlan `mgmt` with `parent: ens192`, gateway e.g. `10.10.20.254`, attach **`Mg0/RP0/CPU0/0`** per router with `snoop_v4` / `snoop_v4_default_route` and static IPs. Prefer **`10.10.20.110+`** to avoid SR lab range `101–108`.

After `xr-compose` generates `docker-compose.yml`, fix mgmt iface name for macvlan:

```bash
sed -i 's/linux:xr-n[0-9]*,xr_name=Mg0/linux:eth0,xr_name=Mg0/g' docker-compose.yml
```

**Note:** macvlan IPs are **not** reachable from the host; use external L2/VPN or `docker attach`. Router configs already suit `snoop_v4`.

## Checklist

- [ ] `export DOCKER_API_VERSION=1.43`
- [ ] `~/bin` on PATH if using `just`
- [ ] Bring-up: `xr-compose` **without `-l`**, then **`docker-compose up -d`** (not `docker compose`, not `just launch`)
- [ ] `XR_LAB_XRD_IMAGE` = local tag from `docker images`
- [ ] Static-IP networks: explicit `gateway` in IPAM
- [ ] `mgmt` macvlan on `ens192`; `Mg0/RP0/CPU0/0` + `snoop_v4` on each XRd service
- [ ] Generated compose: `linux:eth0` on mgmt (`XR_MGMT_INTERFACES`), not `linux:xr-n<N>`
