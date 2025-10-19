A lightweight toolkit to manage the original PowerShell utilities for **Spicetify**, **Vencord**, Minecraft servers, and more—now rewritten in TypeScript with Bun.

## 🚀 Features

-   Install **Spicetify** using the upstream installer
-   Download, update, and inject the **EagleCord** fork of Vencord
-   Bootstrap projects from Discord or Next.js templates
-   Automate updates for the legacy PowerShell install
-   Launch local Minecraft servers with tuned JVM flags
-   Uninstall the old PowerShell distribution cleanly

---

## ▶️ Running the CLI

```bash
bun src/cli.ts <command>
```

Global flags:

-   `--silent` – suppress log output
-   `--debug` – enable verbose debug logging

---

## 🛠 Commands

| Command        | Aliases                 | Description                                                |
| -------------- | ----------------------- | ---------------------------------------------------------- |
| `help`         | `--h`, `h`              | Display command information. Use `help <command>` to drill down. |
| `spicetify`    | `s`                     | Run the official Spicetify installer via PowerShell.       |
| `eaglecord`    | `e`, `eaglecord:dev`, `e:dev` | Clone/update the EagleCord fork and inject it. `:dev` forces a reinstall. |
| `create`       | `c`                     | Scaffold a project from the Discord or Next.js templates.  |
| `update`       | `u`                     | Fetch the latest PowerShell release and refresh the install. |
| `uninstall`    | `rem`                   | Remove the legacy PowerShell scripts and cleanup aliases.  |
| `version`      | `v`                     | Show the current CLI version and repository link.          |
| `minecraft`    | `m`                     | Start a Minecraft server from `~/Documents/mc-servers`.    |
| `eagle`        | —                       | Playful animation inspired by the original script.         |

---

## 📦 Legacy PowerShell Installers

The original PowerShell scripts still live in [`powershell/`](powershell/). Use the `update` and `uninstall` commands above to manage that installation from the new TypeScript CLI.

---

## 🧼 Uninstall

```bash
bun src/cli.ts uninstall
```

This removes `C:\Scripts\eagle.ps1`, the associated `core` directory, the optional `eagle` folder, and clears the `Set-Alias eagle` entry from your PowerShell profile.
