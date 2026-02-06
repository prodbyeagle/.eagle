use clap::Command;

use crate::commands;

pub fn build_cli() -> Command {
	let mut cmd = Command::new("eagle")
		.about("eagle - native CLI toolbox")
		.disable_help_subcommand(true)
		.version(env!("CARGO_PKG_VERSION"))
		.arg_required_else_help(true);

	for spec in commands::iter_specs() {
		cmd = cmd.subcommand((spec.command)());
	}

	cmd
}
