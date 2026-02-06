use std::path::{Path, PathBuf};

use clap::{Arg, ArgMatches, Command};
use dialoguer::{Input, Select};

use crate::commands::CommandSpec;
use crate::context::Context;

fn build() -> Command {
	Command::new("minecraft")
		.about("Minecraft server tools (start, create)")
		.alias("m")
		.arg(
			Arg::new("ram_mb")
				.long("ram-mb")
				.help("RAM in MB")
				.value_parser(clap::value_parser!(u32))
				.required(false),
		)
		.subcommand(
			Command::new("create")
				.about("Create a new Minecraft server")
				.arg(
					Arg::new("name")
						.long("name")
						.short('n')
						.help("Server name (folder name)")
						.required(false),
				)
				.arg(
					Arg::new("type")
						.long("type")
						.short('t')
						.help("Server type: paper | fabric")
						.value_parser(["paper", "fabric"])
						.required(false),
				)
				.arg(
					Arg::new("version")
						.long("version")
						.short('v')
						.help("Minecraft version (e.g. 1.21.4)")
						.required(false),
				)
				.arg(
					Arg::new("port")
						.long("port")
						.help("Server port")
						.value_parser(clap::value_parser!(u16))
						.default_value("22222"),
				)
				.arg(
					Arg::new("motd")
						.long("motd")
						.help("Server motd")
						.default_value("eagle minecraft server"),
				)
				.arg(
					Arg::new("force")
						.long("force")
						.help("Overwrite if the folder already exists")
						.action(clap::ArgAction::SetTrue),
				)
				.arg(
					Arg::new("skip_download")
						.long("skip-download")
						.help("Only create config files (no jar download)")
						.action(clap::ArgAction::SetTrue),
				),
		)
}

fn run(matches: &ArgMatches, _: &Context) -> anyhow::Result<()> {
	match matches.subcommand() {
		Some(("create", sub)) => run_create(sub),
		Some((other, _)) => anyhow::bail!("Unknown subcommand: {other}"),
		None => run_start(matches),
	}
}

fn run_start(matches: &ArgMatches) -> anyhow::Result<()> {
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

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ServerType {
	Paper,
	Fabric,
}

impl ServerType {
	fn as_str(self) -> &'static str {
		match self {
			Self::Paper => "paper",
			Self::Fabric => "fabric",
		}
	}
}

fn run_create(matches: &ArgMatches) -> anyhow::Result<()> {
	let name = matches
		.get_one::<String>("name")
		.map(|s| s.to_string())
		.unwrap_or_else(prompt_server_name);

	validate_server_name(&name)?;

	let server_type = matches
		.get_one::<String>("type")
		.map(|s| s.as_str())
		.map(parse_server_type)
		.transpose()?
		.unwrap_or_else(select_server_type);

	let version = matches
		.get_one::<String>("version")
		.map(|s| s.to_string())
		.unwrap_or_else(prompt_version);

	let port = *matches.get_one::<u16>("port").unwrap_or(&22222);
	let motd = matches
		.get_one::<String>("motd")
		.map(|s| s.to_string())
		.unwrap_or_else(|| "eagle minecraft server".to_string());

	let force = matches.get_flag("force");
	let skip_download = matches.get_flag("skip_download");

	let root = documents_dir()
		.ok_or_else(|| anyhow::anyhow!("Could not resolve Documents dir"))?
		.join("mc-servers");

	std::fs::create_dir_all(&root)?;

	let server_dir = root.join(&name);
	if server_dir.exists() {
		if !force {
			anyhow::bail!(
				"Folder already exists: {} (use --force)",
				server_dir.display()
			);
		}
		std::fs::remove_dir_all(&server_dir)?;
	}

	std::fs::create_dir_all(&server_dir)?;
	let mut guard = DirGuard::new(server_dir.clone());

	write_eula(&server_dir)?;
	write_server_properties(&server_dir, port, &motd)?;

	if !skip_download {
		let jar_path = server_dir.join("server.jar");
		match server_type {
			ServerType::Paper => download_paper_server(&version, &jar_path)?,
			ServerType::Fabric => download_fabric_server(&version, &jar_path)?,
		}
	}

	println!(
		"Created server: {} ({}, {})",
		server_dir.display(),
		server_type.as_str(),
		version
	);
	println!("Port: {port}");
	println!("Motd: {motd}");

	guard.commit();
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

fn prompt_server_name() -> String {
	Input::<String>::new()
		.with_prompt("Server name")
		.interact_text()
		.unwrap_or_else(|_| "mc-server".to_string())
}

fn prompt_version() -> String {
	Input::<String>::new()
		.with_prompt("Minecraft version (e.g. 1.21.4)")
		.interact_text()
		.unwrap_or_else(|_| "1.21.4".to_string())
}

fn select_server_type() -> ServerType {
	let options = ["paper", "fabric"];
	let selection = Select::new()
		.with_prompt("Server type")
		.items(&options)
		.default(0)
		.interact()
		.unwrap_or(0);

	if options[selection] == "fabric" {
		ServerType::Fabric
	} else {
		ServerType::Paper
	}
}

fn parse_server_type(s: &str) -> anyhow::Result<ServerType> {
	match s.to_lowercase().as_str() {
		"paper" => Ok(ServerType::Paper),
		"fabric" => Ok(ServerType::Fabric),
		_ => anyhow::bail!("Invalid type: {s} (expected: paper | fabric)"),
	}
}

fn validate_server_name(name: &str) -> anyhow::Result<()> {
	if name.trim().is_empty() {
		anyhow::bail!("Name must not be empty");
	}

	let invalid = ['<', '>', ':', '"', '/', '\\', '|', '?', '*'];
	if name.chars().any(|c| invalid.contains(&c)) {
		anyhow::bail!(
			"Invalid name. Windows folder names cannot contain: <>:\"/\\|?*"
		);
	}

	if name.contains("..") {
		anyhow::bail!("Invalid name: '..' not allowed");
	}

	Ok(())
}

fn write_eula(server_dir: &Path) -> anyhow::Result<()> {
	let content = "# By changing the setting below to TRUE you are indicating your\n# agreement to our EULA (https://aka.ms/MinecraftEULA).\n" .to_string()
		+ "eula=true\n";

	std::fs::write(server_dir.join("eula.txt"), content)?;
	Ok(())
}

fn write_server_properties(
	server_dir: &Path,
	port: u16,
	motd: &str,
) -> anyhow::Result<()> {
	let mut lines = Vec::new();
	lines.push("enable-jmx-monitoring=false".to_string());
	lines.push(format!("server-port={port}"));
	lines.push("server-ip=".to_string());
	lines.push(format!("motd={motd}"));
	lines.push("enable-command-block=false".to_string());
	lines.push("online-mode=true".to_string());
	lines.push("level-name=world".to_string());
	lines.push("gamemode=survival".to_string());
	lines.push("difficulty=easy".to_string());
	lines.push("max-players=20".to_string());
	lines.push("view-distance=10".to_string());
	lines.push("simulation-distance=10".to_string());
	lines.push("spawn-protection=16".to_string());
	lines.push("sync-chunk-writes=true".to_string());
	lines.push("enable-rcon=false".to_string());
	lines.push("enable-query=false".to_string());
	lines.push("enforce-secure-profile=true".to_string());
	lines.push("white-list=false".to_string());
	lines.push("pvp=true".to_string());
	lines.push("allow-flight=false".to_string());
	lines.push("generate-structures=true".to_string());
	lines.push("level-seed=".to_string());
	lines.push("allow-nether=true".to_string());
	lines.push("spawn-animals=true".to_string());
	lines.push("spawn-monsters=true".to_string());
	lines.push("spawn-npcs=true".to_string());
	lines.push("use-native-transport=true".to_string());

	std::fs::write(
		server_dir.join("server.properties"),
		format!("{}\n", lines.join("\n")),
	)?;

	Ok(())
}

fn download_paper_server(version: &str, jar_path: &Path) -> anyhow::Result<()> {
	println!("Downloading Paper {version}...");

	let meta_url =
		format!("https://api.papermc.io/v2/projects/paper/versions/{version}");
	let meta = fetch_json(&meta_url)?;
	let builds = meta
		.get("builds")
		.and_then(|v| v.as_array())
		.ok_or_else(|| anyhow::anyhow!("Unexpected Paper API response"))?;

	let mut best: Option<u64> = None;
	for b in builds {
		if let Some(n) = b.as_u64() {
			best = Some(best.map(|x| x.max(n)).unwrap_or(n));
		}
	}

	let build = best.ok_or_else(|| anyhow::anyhow!("No builds found"))?;
	let url = format!(
		"https://api.papermc.io/v2/projects/paper/versions/{version}/builds/{build}/downloads/paper-{version}-{build}.jar"
	);
	download_file(&url, jar_path)?;
	Ok(())
}

fn download_fabric_server(
	version: &str,
	jar_path: &Path,
) -> anyhow::Result<()> {
	println!("Downloading Fabric {version}...");

	let loader_meta_url =
		format!("https://meta.fabricmc.net/v2/versions/loader/{version}");
	let combos = fetch_json(&loader_meta_url)?;
	let combos = combos
		.as_array()
		.ok_or_else(|| anyhow::anyhow!("Unexpected Fabric meta response"))?;

	let best = combos
		.iter()
		.find(|c| {
			c.get("loader")
				.and_then(|l| l.get("stable"))
				.and_then(|s| s.as_bool())
				.unwrap_or(true)
				&& c.get("installer")
					.and_then(|i| i.get("stable"))
					.and_then(|s| s.as_bool())
					.unwrap_or(true)
		})
		.or_else(|| combos.first())
		.ok_or_else(|| anyhow::anyhow!("No loader versions found"))?;

	let loader = best
		.get("loader")
		.and_then(|l| l.get("version"))
		.and_then(|v| v.as_str())
		.ok_or_else(|| anyhow::anyhow!("Missing loader version"))?;

	let installer = best
		.get("installer")
		.and_then(|l| l.get("version"))
		.and_then(|v| v.as_str())
		.ok_or_else(|| anyhow::anyhow!("Missing installer version"))?;

	let url = format!(
		"https://meta.fabricmc.net/v2/versions/loader/{version}/{loader}/{installer}/server/jar"
	);
	download_file(&url, jar_path)?;
	Ok(())
}

fn fetch_json(url: &str) -> anyhow::Result<serde_json::Value> {
	let resp = ureq::get(url).call()?;
	let status = resp.status();
	if status != 200 {
		anyhow::bail!("HTTP {status} for {url}");
	}

	let mut reader = resp.into_body().into_reader();
	let mut buf = Vec::new();
	std::io::Read::read_to_end(&mut reader, &mut buf)?;

	let json: serde_json::Value = serde_json::from_slice(&buf)?;
	Ok(json)
}

fn download_file(url: &str, out_path: &Path) -> anyhow::Result<()> {
	use std::io::Write;

	let resp = ureq::get(url).call()?;
	let status = resp.status();
	if status != 200 {
		anyhow::bail!("Download failed (HTTP {status})");
	}

	let mut reader = resp.into_body().into_reader();
	let mut file = std::fs::File::create(out_path)?;
	std::io::copy(&mut reader, &mut file)?;
	file.flush()?;

	Ok(())
}

struct DirGuard {
	path: PathBuf,
	committed: bool,
}

impl DirGuard {
	fn new(path: PathBuf) -> Self {
		Self {
			path,
			committed: false,
		}
	}

	fn commit(&mut self) {
		self.committed = true;
	}
}

impl Drop for DirGuard {
	fn drop(&mut self) {
		if self.committed {
			return;
		}

		let _ = std::fs::remove_dir_all(&self.path);
	}
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
