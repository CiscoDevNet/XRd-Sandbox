# Local User Configuration Injection

This script allows you to inject fallback local user authentication configuration into XRd startup files before deployment.

## Purpose

The goal is to have a fallback local username/password in case the TACACS authentication fails or is unreachable. This local user serves as a backup authentication method when TACACS is configured on the device but the TACACS server is not accessible. Since this is a public repository, credentials cannot be hardcoded in the repository files.

## Files

- `inject-local-user.sh` - Script that injects the local user configuration
- `fallback_local_user.cfg` - Default local user configuration used when environment variables are not set

## Usage

### Using Custom Credentials (via Environment Variables)

Set the `FALLBACK_LOCAL_USERNAME` and `FALLBACK_LOCAL_PASSWORD` environment variables before running the script:

```bash
export FALLBACK_LOCAL_USERNAME="myuser"
export FALLBACK_LOCAL_PASSWORD="mypassword"
make inject-local-user-always-on
```

Or inline:

```bash
FALLBACK_LOCAL_USERNAME="myuser" FALLBACK_LOCAL_PASSWORD="mypassword" make inject-local-user-always-on
```

The script will:

1. Generate a SHA-512 password hash (IOS-XR type 10 secret)
2. Create the username configuration block
3. Inject it at the beginning of each `xrd-*-startup.cfg` file in the always-on topology

### Using Default Credentials

If environment variables are not set, the script uses the default local user configuration from `fallback_local_user.cfg`:

```bash
make inject-local-user-always-on
```

Default credentials:

- Username: `cisco`
- Password: `cisco123` (already hashed)

## How It Works

1. The script checks if `FALLBACK_LOCAL_USERNAME` and `FALLBACK_LOCAL_PASSWORD` environment variables are set
2. If set:
   - Uses Python's `crypt` module to generate a SHA-512 password hash
   - Creates a configuration block with the provided username and hashed password
3. If not set:
   - Uses the default local user configuration from `fallback_local_user.cfg`
4. Injects the configuration at the beginning of each startup file
5. Skips files that already contain username configuration to avoid duplicates

## Configuration Format

The injected configuration follows this format:

```text
username <USERNAME>
 group root-lr
 group cisco-support
 secret 10 <SHA512_HASH>
!
```

## Notes

- This script configures a **fallback local user** for when TACACS authentication is configured but the TACACS server is unreachable
- If TACACS is never configured on the device, the standard XRd default authentication will be used
- The script will skip injection if a username configuration already exists in the file
- Configuration is inserted at the beginning of the startup file
- The script works with the always-on topology by default
- Password hashes are generated using SHA-512 (IOS-XR type 10 secret)

## Security Considerations

- Never commit files with real credentials to the repository
- Use environment variables for sensitive credentials
- The default configuration uses a well-known password for demo purposes only
- For production use, always set custom credentials via environment variables
