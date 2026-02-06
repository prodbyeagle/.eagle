use std::path::PathBuf;

use clap::{Arg, ArgMatches, Command};
use dialoguer::{Input, Select};

use crate::commands::CommandSpec;
use crate::context::Context;
use crate::util;

fn build() -> Command {
	Command::new("create")
		.about("Create a new project from a template")
		.alias("c")
		.arg(
			Arg::new("name")
				.long("name")
				.short('n')
				.help("Project name")
				.required(false),
		)
		.arg(
			Arg::new("template")
				.long("template")
				.short('t')
				.help("Template: discord | next | typescript")
				.required(false),
		)
}

fn run(matches: &ArgMatches, _: &Context) -> anyhow::Result<()> {
	let name = matches
		.get_one::<String>("name")
		.cloned()
		.unwrap_or_else(prompt_name);

	let template = matches
		.get_one::<String>("template")
		.map(|s| s.to_string())
		.unwrap_or_else(select_template);

	let template = template.to_lowercase();

	let year = current_two_digit_year()?;
	let base_root = format!(r"D:\Development\.{year}");

	let target_root = match template.as_str() {
		"discord" => PathBuf::from(base_root).join("discord"),
		"next" => PathBuf::from(base_root).join("frontend"),
		"typescript" => PathBuf::from(base_root).join("typescript"),
		_ => anyhow::bail!("Invalid template: {template}"),
	};

	std::fs::create_dir_all(&target_root)?;

	let project_path = target_root.join(&name);
	if project_path.exists() {
		anyhow::bail!("Project already exists: {}", project_path.display());
	}

	let repo_url = match template.as_str() {
		"discord" => "https://github.com/meowlounge/discord-template.git",
		"next" => "https://github.com/meowlounge/next-template.git",
		"typescript" => "https://github.com/meowlounge/typescript-template.git",
		_ => unreachable!(),
	};

	let status = std::process::Command::new("git")
		.arg("clone")
		.arg(repo_url)
		.arg(&project_path)
		.stdin(std::process::Stdio::inherit())
		.stdout(std::process::Stdio::inherit())
		.stderr(std::process::Stdio::inherit())
		.status()?;
	if !status.success() {
		anyhow::bail!("git clone failed");
	}

	let git_dir = project_path.join(".git");
	if git_dir.exists() {
		std::fs::remove_dir_all(git_dir)?;
	}

	let status = util::run_inherit_with_dir(
		"bun",
		&["update", "--latest"],
		&project_path,
	)?;
	if !status.success() {
		anyhow::bail!("bun update failed");
	}

	println!("Project created: {}", project_path.display());
	Ok(())
}

fn prompt_name() -> String {
	Input::<String>::new()
		.with_prompt("Enter project name")
		.interact_text()
		.unwrap_or_else(|_| "project".to_string())
}

fn select_template() -> String {
	let options = ["discord", "next", "typescript"];
	let selection = Select::new()
		.with_prompt("Choose a template")
		.items(&options)
		.default(0)
		.interact()
		.unwrap_or(0);
	options[selection].to_string()
}

fn current_two_digit_year() -> anyhow::Result<String> {
	let now = time::OffsetDateTime::now_local()
		.unwrap_or_else(|_| time::OffsetDateTime::now_utc());
	let year = now.year() % 100;
	Ok(format!("{year:02}"))
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
