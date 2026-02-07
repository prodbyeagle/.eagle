use std::path::Path;

use clap::{Arg, ArgMatches, Command};

use crate::commands::CommandSpec;
use crate::context::Context;
use crate::net;

fn build() -> Command {
	Command::new("update")
		.about("Update eagle.exe in place (Windows)")
		.alias("u")
		.arg(
			Arg::new("force")
				.long("force")
				.help("Run even if this looks like a dev binary")
				.action(clap::ArgAction::SetTrue),
		)
}

fn run(matches: &ArgMatches, ctx: &Context) -> anyhow::Result<()> {
	let force = matches.get_flag("force");
	if is_dev_exe(&ctx.exe_path) && !force {
		anyhow::bail!("Refusing to self-update a dev binary. Use --force.");
	}

	let url = "https://github.com/prodbyeagle/eaglePowerShell/releases/latest/download/eagle.exe";

	let new_path = ctx.exe_dir.join("eagle.new.exe");
	println!("Downloading: {url}");
	net::download_to_file(url, &new_path)?;

	let pid = std::process::id();
	let exe_path = ctx.exe_path.to_string_lossy().to_string();
	let new_path_s = new_path.to_string_lossy().to_string();

	let script = format!(
		"Wait-Process -Id {pid}; Start-Sleep -Milliseconds 200; \
Move-Item -Force '{new_path_s}' '{exe_path}'"
	);

	std::process::Command::new("powershell")
		.args([
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-WindowStyle",
			"Hidden",
			"-Command",
			&script,
		])
		.spawn()?;

	println!("Update scheduled. Re-run eagle in a new shell.");
	Ok(())
}

fn is_dev_exe(path: &Path) -> bool {
	let s = path.to_string_lossy().to_lowercase();
	s.contains("\\target\\debug\\") || s.contains("\\target\\release\\")
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
