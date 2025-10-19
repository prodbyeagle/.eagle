A lightweight PowerShell utility to manage tools like **Spicetify**, **Vencord**, and automate basic script handling such as install, update, and uninstall.

## 🚀 Features

-   Install **Spicetify** easily
-   Download & run **Vencord Installer**
-   Automatic script update checking
-   Clean uninstall with profile and path cleanup
-   Alias setup for easy access via `eagle` command

---

## 📦 Installation

Run the following PowerShell command:

```powershell
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/prodbyeagle/eagle/main/installer.ps1 | Invoke-Expression
```

This will:

-   Download the latest `eagle.ps1` to `C:\Scripts`
-   Add a `eagle` alias to your PowerShell profile
-   Add `C:\Scripts` to your `PATH` (if not already)
-   Enable access via `eagle` from any terminal

---

## 🛠 Usage

```powershell
eagle [command]
```

### Available Commands:

```powershell
eagle help or eagle --h
eagle status
```

`status` shows the current progress of the TypeScript rewrite so contributors know what still needs attention.

---

## 🧼 Uninstall

```powershell
eagle uninstall or eagle --rem
```

This will:

-   Delete `eagle.ps1`
-   Remove the alias from your PowerShell profile
-   Clean up the `C:\Scripts` folder (if not empty)
