## **PC Gaming Redistributable Packages AIO Installer**
Written by [@harryeffinpotter](https://github.com/harryeffinpotter) & greatly improved upon by the legendary [@skrimix](https://github.com/skrimix)

---

### DECEMBER 2025 UPDATE:
- **Fixed silent failing** - Script no longer pretends everything is fine when WinGet is broken/missing
- **WinGet auto-install** - Automatic installation under more scenarios/fresh Windows installs
- **Better detection** - Added extensive checks to verify WinGet is actually working
- **ARM64 skip** - No longer attempts to install ARM64 packages on x64 systems
- **Fresh install support** - Should now work on fresh Windows installs (user testing appreciated!)

---

## Quick Install
Open **PowerShell** and run:
```powershell
iwr -useb https://s.hfnp.dev/PCGR | iex
```

---

[![Github All Releases](https://img.shields.io/github/downloads/harryeffinpotter/PC-Gaming-Redists/total.svg)]()  ![](https://komarev.com/ghpvc/?username=harryeffinpotter) (since 04-12-2024)

## Troubleshooting
If for whatever reason when you try to run the script you get [this error (Click to view)](https://i.imgur.com/TOvxPUq.png), simply [click here to download WinGet.msixbundle](https://github.com/harryeffinpotter/PC-Gaming-Redists/raw/main/WinGet.msixbundle), run it, and click Update/Install. Then try the install command above again.
