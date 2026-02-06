# eagle (Rust CLI)

## Goals

- Native, fast startup, single binary (`eagle.exe`)
- Same features as the previous CLI (help/version/spicetify/eaglecord/create/minecraft/update/uninstall)
- Easy to add a new command without touching a central switch statement

## Plan (Step By Step)

1. Define a command registry type (`CommandSpec`) with:
   - `command(): clap::Command`
   - `run(matches, context) -> Result<()>`
2. Use `inventory` to auto-collect `CommandSpec` entries at link-time.
3. Build the root CLI at runtime by iterating all registered commands and
   adding them as subcommands.
4. Dispatch the selected subcommand by matching the subcommand name and
   calling its `run`.
5. Keep each feature as its own module in `src/commands/`.

## Pseudocode

```text
Context = {
  exe_path, exe_dir, version, repo_url
}

CommandSpec = {
  command(): clap.Command
  run(matches, Context): Result
}

collect all CommandSpec via inventory

build_cli():
  root = clap.Command("eagle").version(...)
  for spec in inventory:
    root.add_subcommand(spec.command())
  return root

main():
  ctx = Context::new()
  cli = build_cli()
  matches = cli.parse()
  (name, submatches) = matches.subcommand()
  spec = inventory.find(|s| s.command().name == name)
  spec.run(submatches, ctx)
```

## Adding A Command

1. Create a file `src/commands/<name>.rs`.
2. Implement `build() -> clap::Command` and `run(...)`.
3. Register via `inventory::submit!(CommandSpec { ... })`.
4. Add `pub mod <name>;` in `src/commands/mod.rs`.

