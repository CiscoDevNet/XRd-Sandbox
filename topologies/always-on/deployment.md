# Sandbox Always-On Topology Deployment Guide

> [!IMPORTANT]
> All scripts and commands in this guide are intended to be run from the root directory of the XRd-Sandbox repository.

> [!NOTE]
> The automated deployment creates temporary deployment configuration files (`*.deploy.cfg`) from the base startup configs.
> These deployment files are modified with TACACS/AAA/local user settings and are **not tracked by Git**.

## 🚀 Deployment Scenarios

### For Sandbox Team (DevNet Sandbox Infrastructure)

> [!IMPORTANT]
> Required: Environment variables must be defined in a `.env` file in the root directory of the XRd-Sandbox repository.

This deployment is for the official DevNet Always-On sandbox and requires TACACS+ authentication configuration.

**Setup and Deploy:**

```bash
# 1. Create a .env file with TACACS+ and fallback credentials
cat > .env << 'EOF'
TACACS_SERVER_HOST=192.168.1.100
TACACS_SERVER_SECRET=your-secret
FALLBACK_LOCAL_USERNAME=admin
FALLBACK_LOCAL_PASSWORD=secure-password
EOF
```

# 2. Deploy with sudo (required for sandbox infrastructure)

```bash
sudo make -C /home/developer/XRd-Sandbox deploy-always-on
```

**Undeploy:**

```bash
sudo make -C /home/developer/XRd-Sandbox undeploy-always-on
```

---

### For Regular Users (Your Own Environment)

This deployment is for users running the topology on thei XRd reservable sandbox.

```bash
# Optional: Create a .env file to customize credentials
cat > .env << 'EOF'
FALLBACK_LOCAL_USERNAME=myuser
FALLBACK_LOCAL_PASSWORD=mypassword
EOF
```

> [!NOTE]
> Optional: You can deploy without a `.env` file. Default credentials (cisco/cisco123) will be used.

# Deploy with custom credentials

```bash
make -C /home/developer/XRd-Sandbox deploy-always-on
```

**Monitor logs:**

```bash
make -C /home/developer/XRd-Sandbox follow-always-on-logs
```

**Undeploy:**

```bash
make -C /home/developer/XRd-Sandbox undeploy-always-on
```

## 📋 Environment Variables

| Variable                  | Required | Default    | Description               |
| ------------------------- | -------- | ---------- | ------------------------- |
| `TACACS_SERVER_HOST`      | No       | -          | TACACS+ server IP address |
| `TACACS_SERVER_SECRET`    | No       | -          | TACACS+ shared secret key |
| `FALLBACK_LOCAL_USERNAME` | No       | `cisco`    | Local fallback username   |
| `FALLBACK_LOCAL_PASSWORD` | No       | `cisco123` | Local fallback password   |

> [!NOTE]
> Both `TACACS_SERVER_HOST` and `TACACS_SERVER_SECRET` must be set together. If only one is provided, deployment will fail.

## 🔐 Authentication Configuration Flow

```mermaid
flowchart TD
    Start([Make deploy-always-on]) --> CheckTACACS{TACACS env vars<br/>set?}

    CheckTACACS -->|Both set| InjectTACACS[Inject TACACS config]
    CheckTACACS -->|None set| SkipTACACS[Skip TACACS]
    CheckTACACS -->|Only one set| Error[❌ Deployment fails]

    InjectTACACS --> InjectAAA[Inject AAA config]
    InjectAAA --> CheckLocalUser{Local user<br/>env vars set?}

    SkipTACACS --> CheckLocalUser

    CheckLocalUser -->|Yes| CustomUser[Create custom local user]
    CheckLocalUser -->|No| DefaultUser[Use default user<br/>cisco/cisco123]

    CustomUser --> Deploy[Build and Deploy XRd containers]
    DefaultUser --> Deploy

    Deploy --> AuthFlow{Login attempt}

    AuthFlow -->|TACACS configured| TryTACACS[Try TACACS+ server]
    AuthFlow -->|No TACACS| UseLocal[Use local user]

    TryTACACS -->|Success| LoginOK[✅ Login successful]
    TryTACACS -->|Fail| Fallback[Fallback to local user]

    Fallback --> LoginOK
    UseLocal --> LoginOK

    style Error fill:#f88,stroke:#f00
    style LoginOK fill:#8f8,stroke:#0f0
```

## 🔧 Manual Deployment

### Local User Only, No TACACS+

```bash
# Create a .env file with your configuration (optional)
cat > .env << 'EOF'
FALLBACK_LOCAL_USERNAME=cisco
FALLBACK_LOCAL_PASSWORD=C1sco12345
EOF

# If you do not set the above variables, defaults (cisco/C1sco12345) will be used.
# if you do not run this script, no local user will be created and XRd will prompt for user creation on first boot.
./scripts/deployment/always-on/inject-local-user.sh

# Create deployment config files from base configs
# The idea is to keep the base configs unchanged for version control
for i in 1 2 3; do cp topologies/always-on/xrd-$i-startup.cfg topologies/always-on/xrd-$i-startup.deploy.cfg; done

# Generate and deploy
# Update the XRd version accordingly. 25.3.1, the version used in this example, may be outdated.
# The automated deployment (make deploy-always-on) always uses the version set in the .sandbox_env_vars file.
xr-compose \
  --input-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.xr.yml \
  --output-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  --image ios-xr/xrd-control-plane:25.3.1

sed -i.bak 's/linux:xr-30/linux:eth0/g' \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml

docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  up --detach
```

## 📝 Injected Configuration Examples

TACACS+ Server Config

```text
tacacs source-interface MgmtEth0/RP0/CPU0/0 vrf default
tacacs-server host <TACACS_SERVER_HOST> port 49
 key 0 <TACACS_SERVER_SECRET>
```

For aaa config, see [aaa-config.cfg file.](../../scripts/deployment/always-on/aaa-config.cfg)

For the local user config, [see the fallback_local_user.cfg file.](../../scripts/deployment/always-on/fallback_local_user.cfg)

## ⚠️ TACACS+ Requirements for NETCONF/GNMI

> [!IMPORTANT]
> For NETCONF and GNMI connections to work with TACACS+ authentication, the TACACS+ server **must** send the following attribute-value (AV) pair:

**Mandatory Attribute:**

- **Attribute:** `task`
- **Value:** `rwx:,#root-lr`

This task attribute grants the necessary permissions for NETCONF/GNMI operations. Without this AV pair, NETCONF and GNMI connections will fail.

**Reference:** [Configure ASR9K TACACS+ with Cisco Identity Services Engine](https://www.cisco.com/c/en/us/support/docs/security/identity-services-engine-24/214018-configure-asr9k-tacacs-with-cisco-identi.html)

## 🔍 Troubleshooting

| Issue               | Solution                                                                      |
| ------------------- | ----------------------------------------------------------------------------- |
| TACACS+ not applied | Verify both `TACACS_SERVER_HOST` and `TACACS_SERVER_SECRET` are set           |
| Password hash fails | Ensure Python 3 is installed: `python3 --version`                             |
| No user configured  | Check startup files: `grep "username" topologies/always-on/xrd-1-startup.cfg` |

### Console Access

> [!NOTE]
> Console access via `docker attach` is **only available when deploying the topology on your own VM/environment**. The always-on sandbox that is already deployed does not provide console access to end users.

**Accessing the XRd Console (recommended method):**

This command should be executed on the VM hosting the containers:

```bash
docker attach <xrd-container>
# Press Enter to get the prompt
```

**To exit the attached session:**

- Use `Ctrl-P`, `Ctrl-Q` to detach without stopping the container
- ⚠️ This escape sequence **only works with standard terminal clients**
- VSCode's integrated terminal does **not support** this escape sequence

**Alternative method (bypasses security checks):**

You can still access the XRd CLI using:

```bash
docker exec -it <XRD_CONTAINER_NAME> bash
# Then run:
/pkg/bin/xr_cli
```

Useful when you want to run a show command directly from docker, for example:

```bash
docker exec xrd-1 /pkg/bin/xr_cli "show netconf-yang clients"
```

> [!WARNING]
> Using `docker exec` bypasses some security checks. Use `docker attach` when possible.

## 📚 Additional Resources

- You can find the script to deploy this sandbox on the [deployment/always-on directory.](../../scripts/deployment/always-on/)
