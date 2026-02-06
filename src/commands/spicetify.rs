use clap::{ArgMatches, Command};

use crate::commands::CommandSpec;
use crate::context::Context;
use crate::util;

fn build() -> Command {
	Command::new("spicetify")
		.about("Install Spicetify")
		.alias("s")
}

fn run(_: &ArgMatches, _: &Context) -> anyhow::Result<()> {
	let url =
		"https://raw.githubusercontent.com/spicetify/cli/main/install.ps1";

	let script = format!("irm '{url}' | iex");
	let status = util::run_inherit(
		"powershell",
		&[
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-Command",
			&script,
		],
	)?;

	if !status.success() {
		anyhow::bail!("Spicetify install failed (exit code: {status})");
	}

	Ok(())
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
