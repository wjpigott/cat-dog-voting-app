# Environment Configuration

This project uses environment variables to protect sensitive information like IP addresses.

## Required Environment Variable

Set your OnPrem public IP address:

```powershell
# PowerShell
$env:ONPREM_PUBLIC_IP = "YOUR_ONPREM_PUBLIC_IP_HERE"

# To make it permanent (Windows):
[Environment]::SetEnvironmentVariable("ONPREM_PUBLIC_IP", "YOUR_IP", "User")
```

```bash
# Bash/Linux
export ONPREM_PUBLIC_IP="YOUR_ONPREM_PUBLIC_IP_HERE"

# To make it permanent, add to ~/.bashrc or ~/.profile
echo 'export ONPREM_PUBLIC_IP="YOUR_IP"' >> ~/.bashrc
```

## Configuration File

Alternatively, you can set values in `config/customer.env` (not tracked in git):

```bash
# Edit config/customer.env
ONPREM_PUBLIC_IP="YOUR_ONPREM_PUBLIC_IP"
ONPREM_ENDPOINT="http://YOUR_ONPREM_PUBLIC_IP:31514"
```

Then source it before running scripts:

```powershell
# PowerShell
Get-Content config/customer.env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2].Trim('"'), "Process")
    }
}
```

## Verification

Check that the variable is set:

```powershell
# PowerShell
Write-Host $env:ONPREM_PUBLIC_IP

# Bash
echo $ONPREM_PUBLIC_IP
```

## Security Best Practices

1. ✅ **Never commit real IP addresses** to public repositories
2. ✅ **Use environment variables** for sensitive values
3. ✅ **Use `config/customer.env`** for local configuration (already in .gitignore)
4. ✅ **Use placeholders** like `YOUR_ONPREM_IP` in documentation
5. ✅ **Review diffs before committing** to ensure no IPs are exposed

## Scripts That Use Environment Variables

All Traffic Manager scripts now read from `$env:ONPREM_PUBLIC_IP`:

- `scripts/fix-traffic-manager-port-31514.ps1`
- `scripts/update-traffic-manager-powershell.ps1`
- `scripts/fix-traffic-manager-and-cleanup.ps1`
- `scripts/quick-fix-traffic-manager.ps1`

If the variable is not set, scripts will display an error with instructions.
