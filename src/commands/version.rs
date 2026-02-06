use clap::{ArgMatches, Command};

use crate::commands::CommandSpec;
use crate::context::Context;

fn build() -> Command {
	Command::new("version")
		.about("Show the current version")
		.alias("v")
}

fn run(_: &ArgMatches, ctx: &Context) -> anyhow::Result<()> {
	println!("eagle {}", ctx.version);
	println!("{}", ctx.repo_url);
	Ok(())
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
