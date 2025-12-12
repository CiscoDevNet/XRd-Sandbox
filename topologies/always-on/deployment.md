# Sandbox Always-On Topology Deployment Guide

## 🚀 Automated Deployment (Recommended)

The easiest way to deploy this topology is using the Makefile targets:

### Deploy the Topology

```bash
make deploy-always-on
```

This automated deployment includes:

- Injection of fallback local user credentials (if configured)
- Injection of TACACS+ AAA configuration (if TACACS environment variables are set)
- Injection of TACACS+ server configuration (if TACACS environment variables are set)
- Generation of docker-compose file
- Deployment of the topology

### Monitor the Topology

```bash
make follow-always-on-logs
```

### Undeploy the Topology

```bash
make undeploy-always-on
```

## 🔐 Authentication Configuration

The deployment process supports both TACACS+ authentication and local user fallback.

### TACACS+ Authentication (Optional)

To configure TACACS+ authentication, set the following environment variables before deployment:

```bash
export TACACS_SERVER_IP="192.168.1.100"
export TACACS_SECRET_KEY="your-tacacs-secret"
make deploy-always-on
```

**What happens when TACACS is configured:**

- TACACS+ server configuration is injected into all XRd startup files
- AAA authentication configuration is added to use TACACS+ with local fallback
- A fallback local user is created in case TACACS+ server is unreachable

**Required Environment Variables:**

- `TACACS_SERVER_IP` - IP address of your TACACS+ server
- `TACACS_SECRET_KEY` - Shared secret key for TACACS+ authentication

> [!NOTE]
> Both variables are required. If only one is set, deployment will fail. If neither is set, TACACS+ configuration is skipped.

### Fallback Local User Configuration

When using `make deploy-always-on`, a fallback local user is automatically configured:

#### Option 1: Custom Credentials (Recommended)

```bash
export FALLBACK_LOCAL_USERNAME="admin"
export FALLBACK_LOCAL_PASSWORD="secure-password"
make deploy-always-on
```

#### Option 2: Default Credentials

If environment variables are not set, default credentials are used:

- Username: `cisco`
- Password: `cisco123`

> **Security Warning:** Default credentials are for demo purposes only. Always use custom credentials in production environments.

### Authentication Priority

When TACACS+ is configured, the authentication order is:

1. TACACS+ server (primary)
2. Local user (fallback)

If TACACS+ environment variables are not set, XRd will use its default authentication behavior (prompting for initial user creation on first boot).

## 🔧 Manual Deployment Steps

If you prefer manual deployment or need to troubleshoot:

> **Important:** When deploying manually, you must configure authentication yourself. The XRd routers will prompt you to create a user on first boot if no authentication is configured in the startup files.

### Option A: Manual Deployment with TACACS+ Authentication

#### Step 1: Set TACACS+ Environment Variables

```bash
export TACACS_SERVER_IP="192.168.1.100"
export TACACS_SECRET_KEY="your-tacacs-secret"
export FALLBACK_LOCAL_USERNAME="admin"
export FALLBACK_LOCAL_PASSWORD="secure-password"
```

#### Step 2: Inject Authentication Configuration

```bash
# Inject fallback local user
./scripts/deployment/always-on/inject-local-user.sh

# Inject TACACS+ AAA configuration
./scripts/deployment/always-on/inject-tacacs-aaa.sh

# Inject TACACS+ server configuration
./scripts/deployment/always-on/inject-tacacs-config.sh
```

#### Step 3: Generate Docker Compose File

```bash
xr-compose \
  --input-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.xr.yml \
  --output-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  --image ios-xr/xrd-control-plane:25.3.1
```

#### Step 4: Update Interface Names

```bash
sed -i.bak 's/linux:xr-30/linux:eth0/g' \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml
```

#### Step 5: Deploy the Topology

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  up --detach
```

### Option B: Manual Deployment without TACACS+ (Local User Only)

#### Step 1: Set Local User Environment Variables (Optional)

```bash
export FALLBACK_LOCAL_USERNAME="admin"
export FALLBACK_LOCAL_PASSWORD="secure-password"
```

#### Step 2: Inject Local User Configuration

```bash
./scripts/deployment/always-on/inject-local-user.sh
```

If you skip this step, XRd will prompt you to create a user when you first connect to each router.

#### Step 3: Generate Docker Compose File

```bash
xr-compose \
  --input-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.xr.yml \
  --output-file /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  --image ios-xr/xrd-control-plane:25.3.1
```

#### Step 4: Update Interface Names

```bash
sed -i.bak 's/linux:xr-30/linux:eth0/g' \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml
```

#### Step 5: Deploy the Topology

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  up --detach
```

### Option C: Manual Deployment without Pre-configured Authentication

If you don't inject any user configuration, follow steps 3-5 from Option B above. When you first connect to each XRd router, you will be prompted to create a user interactively.

### Monitor Logs

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  logs --follow
```

### 🛑 Stopping the Topology

```bash
docker compose --file \
  /home/developer/XRd-Sandbox/topologies/always-on/docker-compose.yml \
  down --volumes --remove-orphans
```

## 📝 Configuration Details

### TACACS+ Server Configuration

When TACACS+ environment variables are set, the following configuration is injected into each XRd startup file:

```text
tacacs source-interface MgmtEth0/RP0/CPU0/0 vrf default
tacacs-server host <TACACS_SERVER_IP> port 49
 key 0 <TACACS_SECRET_KEY>
```

### AAA Configuration

The TACACS+ AAA configuration enables authentication, authorization, and accounting with local fallback:

```text
aaa accounting exec default start-stop group tacacs+
aaa accounting commands default start-stop group tacacs+
aaa authorization exec default group tacacs+ local
aaa authorization commands default group tacacs+ local
aaa authentication login default group tacacs+ local

line console
 accounting exec default
 authorization exec default
 login authentication default

line default
 accounting exec default
 accounting commands default
 authorization exec default
 authorization commands default
 login authentication default
 transport input ssh
```

### Local User Configuration

The fallback local user is configured with:

- User groups: `root-lr` and `cisco-support` (full administrative access)
- Password: SHA-512 hashed (IOS-XR type 10 secret)

Example configuration:

```text
username admin
 group root-lr
 group cisco-support
 secret 10 <SHA512_HASH>
```

## 🔍 Troubleshooting

### Cannot Login After Deployment

**If using TACACS+:**

1. Verify TACACS+ server is reachable from the sandbox network
2. Check that TACACS+ server IP and secret key are correct
3. Try logging in with the fallback local user credentials

**If not using TACACS+:**

1. Check if local user was injected: `grep "username" topologies/always-on/xrd-1-startup.cfg`
2. If no user is configured, connect to the router console - you'll be prompted to create a user

### TACACS+ Configuration Not Applied

Check if environment variables were set before running the deployment:

```bash
echo $TACACS_SERVER_IP
echo $TACACS_SECRET_KEY
```

If they weren't set, you can manually run the injection scripts after setting the variables.

### Password Hash Generation Fails

The local user injection script requires Python 3 with the `crypt` module. Ensure Python 3 is installed:

```bash
python3 --version
```

## 📚 Related Documentation

- [Local User Configuration Details](../../scripts/deployment/always-on/LOCAL_USER_README.md)
- [XRd Documentation](https://www.cisco.com/c/en/us/td/docs/routers/virtual-routers/xrd.html)
