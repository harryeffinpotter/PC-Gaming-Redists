## **PC Gaming Redistributable Packages AIO Installer**
Written by [@harryeffinpotter](https://github.com/harryeffinpotter) & greatly improved upon by the legendary [@skrimix](https://github.com/skrimix)

---
![New look!](https://share.harryeffingpotter.com/u/gaseous-antipodesgreenparakeet.gif)
### DECEMBER 2025 UPDATE:
- **Added cool new look!** - Totally NOT ripped off from Gemini CLI!
- **Fixed silent failing** - Script no longer pretends everything is fine when WinGet is broken/missing
- **WinGet auto-install** - Automatic installation under more scenarios/fresh Windows installs
- **Better detection** - Added extensive checks to verify WinGet is actually working
- **Useless packages skip** - No longer attempts to install ARM64/Uninstaller/Developer packages.
- **Fresh install support** - Should now work on fresh Windows installs (user testing appreciated!)
- **Shortened URL** - Shortened the URL for those of us who can't copy+paste to the target machine easily!

---

## Quick Install

### Option 1:
Open **PowerShell** (**NOT** as administrator) and run:
```powershell
iwr -useb https://s.hfnp.dev/PCGR | iex
```

### Option 2:
Download and run [Install.bat](https://raw.githack.com/harryeffinpotter/PC-Gaming-Redists/main/Install.bat)

---

[![Github All Releases](https://img.shields.io/github/downloads/harryeffinpotter/PC-Gaming-Redists/total.svg)]()  ![](https://komarev.com/ghpvc/?username=harryeffinpotter) (since 04-12-2024)

---

## Unattended / Silent Installation

Both `Install.ps1` and `AIOInstaller.bat` support a **`/Unattend`** (batch) / **`-Unattend`** (PowerShell) flag that:

- Skips all interactive prompts (splash menu, WinGet retry questions, end-of-run pause)
- Enables full logging to `%TEMP%\pcgr_aio_<COMPUTERNAME>.log`
- Auto-retries a broken WinGet up to 5 times (10 s apart) before exiting with code 1
- Returns a non-zero exit code on fatal errors so calling orchestrators can detect failure

### Unattended one-liner (PowerShell 5.1+)

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/harryeffinpotter/PC-Gaming-Redists/main/Install.ps1').Content)) -Unattend
```

> **Tip – fork pinning:** For reproducible deployments, replace `main` with a specific commit SHA
> (e.g. `.../abc1234.../Install.ps1`) so your image is never broken by upstream changes.

### `autounattend.xml` integration

Add this to your `<FirstLogonCommands>` pass (runs as the first logged-on user, **after** a user
account exists — required for WinGet / Microsoft Store packages to work correctly):

```xml
<FirstLogonCommands>
  <SynchronousCommand wcm:action="add">
    <Order>1</Order>
    <RequiresUserInput>false</RequiresUserInput>
    <CommandLine>powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "&amp; { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &amp; ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/harryeffinpotter/PC-Gaming-Redists/main/Install.ps1').Content)) -Unattend }"</CommandLine>
    <Description>Install PC Gaming Redistributables</Description>
  </SynchronousCommand>
</FirstLogonCommands>
```

#### Important notes for `autounattend.xml`

| Topic | Recommendation |
|---|---|
| **Pass to use** | `FirstLogonCommands` (OOBE / first user logon). Do **not** use `specialize` — WinGet and AppX packages require a real user session and the Microsoft Store service to be running. |
| **Already elevated?** | If your `autounattend.xml` sets the account as Administrator, `Install.ps1 -Unattend` detects that and skips the inner UAC re-launch (runs `AIOInstaller.bat /Unattend` directly). |
| **Execution policy** | Always pass `-ExecutionPolicy Bypass` on the outer `powershell.exe` call; do not rely on the machine policy being set before OOBE. |
| **Log location** | `%TEMP%\PC-Gaming-Redists-Install.log` (Install.ps1 transcript) + `%TEMP%\pcgr_aio_<HOSTNAME>.log` (per-package winget log from AIOInstaller.bat). |
| **Exit codes** | Exit `0` = success; exit `1` = fatal error (WinGet unavailable, download failed, or launch failed). Packages that fail individually do **not** abort the run — they are logged and counted in the summary. |

### Running directly from an elevated shell (no UAC popup)

```powershell
# From an elevated PowerShell prompt:
powershell.exe -ExecutionPolicy Bypass -NoProfile -File AIOInstaller.bat /Unattend
# or via Install.ps1 (auto-detects elevation, skips UAC re-launch):
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& { ... } -Unattend"
```

---

## Troubleshooting
If you experience any problems please submit an issue so I can fix all angles of this thing, once and for all!
