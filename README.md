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

### Minecraft

```powershell
# Start an existing server (interactive selector)
eagle minecraft

# Create a new server
eagle minecraft create --name my-server --type paper --version 1.21.4
```

## Dev

```powershell
cargo run -- help
.\scripts\check.ps1
```

On macOS/Linux:

```sh
./scripts/check.sh
```
