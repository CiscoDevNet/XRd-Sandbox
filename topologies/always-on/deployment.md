# Sandbox Always-On Topology Deployment Guide

> [!IMPORTANT]
> All scripts and commands in this guide are intended to be run from root directory of the XRd-Sandbox repository.

## 🚀 Quick Start - Automated Deployment (Recommended)

> [!NOTE]
> The automated deployment creates temporary deployment configuration files (`*.deploy.cfg`) from the base startup configs.
> These deployment files are modified with TACACS/AAA/local user settings and are **not tracked by Git**.

**With TACACS+ authentication:**

> [!IMPORTANT]
> Environment variables must be defined in a `.env` file in the root directory of the XRd-Sandbox repository.

```bash
# Create a .env file with your configuration (all variables are optional)
cat > .env << 'EOF'
TACACS_SERVER_HOST=192.168.1.100
TACACS_SERVER_SECRET=your-secret
FALLBACK_LOCAL_USERNAME=admin
FALLBACK_LOCAL_PASSWORD=secure-password
EOF

make deploy-always-on
```

**Monitor logs:**

```bash
make follow-always-on-logs
```

**Undeploy:**

```bash
make undeploy-always-on
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

## 🔍 Troubleshooting

| Issue               | Solution                                                                      |
| ------------------- | ----------------------------------------------------------------------------- |
| TACACS+ not applied | Verify both `TACACS_SERVER_HOST` and `TACACS_SERVER_SECRET` are set           |
| Password hash fails | Ensure Python 3 is installed: `python3 --version`                             |
| No user configured  | Check startup files: `grep "username" topologies/always-on/xrd-1-startup.cfg` |

## 📚 Additional Resources

- You can find the script to deploy this sandbox on the [deployment/always-on directory.](../../scripts/deployment/always-on/)
