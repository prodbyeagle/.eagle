A lightweight PowerShell CLI to automate a few personal workflows
(Spicetify, EagleCord, project templates, etc.).

## Install

Run in PowerShell:

```powershell
Invoke-WebRequest -UseBasicParsing `
	https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/installer.ps1 |
	Invoke-Expression
```

This installs to `C:\Scripts\eagle` and sets a PowerShell alias `eagle`.

## Usage

```powershell
eagle help
eagle <command> [args]
```

## Dev Install

From the repo root:

```powershell
.\installer.ps1 -Dev
```
