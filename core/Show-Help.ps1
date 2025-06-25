function Show-Help {
  Write-Host ""
  Write-Host "🦅 eaglePower — Available Commands" -ForegroundColor Yellow
  Write-Host "─────────────────────────────────────────────"

  $commands = @(
    @{ Cmd = "spicetify"; Alias = "s"; Desc = "Installs Spicetify" },
    @{ Cmd = "eaglecord"; Alias = "e"; Desc = "Launches or downloads the EagleCord Installer" },
    @{ Cmd = "eaglecord:dev"; Alias = "e:dev"; Desc = "Launches the EagleCord Installer in developer mode. DONT USE!" },
    @{ Cmd = "create"; Alias = "c"; Desc = "Creates a new development project using a template" },
    @{ Cmd = "update"; Alias = "u"; Desc = "Checks for updates to eagle and installs if needed" },
    @{ Cmd = "uninstall"; Alias = "rem"; Desc = "Removes eagle and cleans up the alias and folder" },
    @{ Cmd = "version"; Alias = "v"; Desc = "Displays the current version of the eagle script" },
    @{ Cmd = "help"; Alias = "h"; Desc = "Displays this help message" }
  )

  foreach ($c in $commands) {
    $line = "{0,-15} {1,-12} : {2}" -f $c.Cmd, "($($c.Alias))", $c.Desc
    Write-Host "  $line" -ForegroundColor Blue
  }

  Write-Host "─────────────────────────────────────────────"
}
