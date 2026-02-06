A lightweight native CLI (Rust) to automate a few personal workflows
(Spicetify, EagleCord, project templates, Minecraft server launcher, etc.).

## Install (Windows)

```powershell
Invoke-WebRequest -UseBasicParsing `
	https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/installer.ps1 |
	Invoke-Expression
```

Installs `eagle.exe` to `C:\Scripts` and sets a PowerShell alias `eagle`.

## Usage

```powershell
eagle help
eagle <command> [args]
```

## Dev

```powershell
cd .\eagle-cli
cargo run -- help
```
