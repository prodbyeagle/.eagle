use std::path::{Path, PathBuf};

use clap::{Arg, ArgMatches, Command};
use dialoguer::Select;

use crate::commands::CommandSpec;
use crate::context::Context;

fn build() -> Command {
	Command::new("minecraft")
		.about("Start a Minecraft server from ~/Documents/mc-servers")
		.alias("m")
		.arg(
			Arg::new("ram_mb")
				.long("ram-mb")
				.help("RAM in MB")
				.value_parser(clap::value_parser!(u32))
				.required(false),
		)
}

fn run(matches: &ArgMatches, _: &Context) -> anyhow::Result<()> {
	let ram_mb = *matches.get_one::<u32>("ram_mb").unwrap_or(&8192);

	let root = documents_dir()
		.ok_or_else(|| anyhow::anyhow!("Could not resolve Documents dir"))?
		.join("mc-servers");

	let servers = find_servers(&root)?;
	if servers.is_empty() {
		anyhow::bail!("No servers found in: {}", root.display());
	}

	let items: Vec<String> = servers
		.iter()
		.map(|p| {
			p.file_name()
				.and_then(|s| s.to_str())
				.unwrap_or("server")
				.to_string()
		})
		.collect();

	let selection = Select::new()
		.with_prompt("Select a Minecraft server")
		.items(&items)
		.default(0)
		.interact()?;

	let server_path = &servers[selection];
	let jar_path = server_path.join("server.jar");
	if !jar_path.exists() {
		anyhow::bail!("server.jar not found: {}", jar_path.display());
	}

	crossterm::execute!(
		std::io::stdout(),
		crossterm::terminal::SetTitle(format!(
			"MC-SERVER: {}",
			items[selection]
		))
	)?;

	let java_args = build_java_args(ram_mb, &jar_path);
	let status = std::process::Command::new("java")
		.args(java_args)
		.current_dir(server_path)
		.stdin(std::process::Stdio::inherit())
		.stdout(std::process::Stdio::inherit())
		.stderr(std::process::Stdio::inherit())
		.status()?;

	if !status.success() {
		anyhow::bail!("java exited with: {status}");
	}

	println!("Server stopped.");
	Ok(())
}

fn documents_dir() -> Option<PathBuf> {
	directories::UserDirs::new()
		.and_then(|u| u.document_dir().map(|p| p.to_path_buf()))
}

fn find_servers(root: &Path) -> anyhow::Result<Vec<PathBuf>> {
	if !root.exists() {
		return Ok(Vec::new());
	}

	let mut out = Vec::new();
	for entry in std::fs::read_dir(root)? {
		let entry = entry?;
		let path = entry.path();
		if !path.is_dir() {
			continue;
		}

		if path.join("server.jar").exists() {
			out.push(path);
		}
	}

	out.sort();
	Ok(out)
}

fn build_java_args(ram_mb: u32, jar_path: &Path) -> Vec<String> {
	let ram = format!("-Xmx{ram_mb}M");
	let ram2 = format!("-Xms{ram_mb}M");

	let args = vec![
		ram,
		ram2,
		"-XX:+UseG1GC".to_string(),
		"-XX:+ParallelRefProcEnabled".to_string(),
		"-XX:MaxGCPauseMillis=200".to_string(),
		"-XX:+UnlockExperimentalVMOptions".to_string(),
		"-XX:+DisableExplicitGC".to_string(),
		"-XX:+AlwaysPreTouch".to_string(),
		"-XX:G1NewSizePercent=30".to_string(),
		"-XX:G1MaxNewSizePercent=40".to_string(),
		"-XX:G1HeapRegionSize=8M".to_string(),
		"-XX:G1ReservePercent=20".to_string(),
		"-XX:G1HeapWastePercent=5".to_string(),
		"-XX:G1MixedGCCountTarget=4".to_string(),
		"-XX:InitiatingHeapOccupancyPercent=15".to_string(),
		"-XX:G1MixedGCLiveThresholdPercent=90".to_string(),
		"-XX:G1RSetUpdatingPauseTimePercent=5".to_string(),
		"-XX:SurvivorRatio=32".to_string(),
		"-XX:+PerfDisableSharedMem".to_string(),
		"-XX:MaxTenuringThreshold=1".to_string(),
		"-Daikars.new.flags=true".to_string(),
		"-Dusing.aikars.flags=https://mcutils.com".to_string(),
		"-jar".to_string(),
		jar_path.to_string_lossy().to_string(),
		"nogui".to_string(),
	];

	args
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
