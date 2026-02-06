use std::process::{Command, ExitStatus, Stdio};

pub fn run_inherit(program: &str, args: &[&str]) -> anyhow::Result<ExitStatus> {
	let mut cmd = Command::new(program);
	cmd.args(args)
		.stdin(Stdio::inherit())
		.stdout(Stdio::inherit())
		.stderr(Stdio::inherit());

	Ok(cmd.status()?)
}

pub fn run_inherit_with_dir(
	program: &str,
	args: &[&str],
	current_dir: &std::path::Path,
) -> anyhow::Result<ExitStatus> {
	let mut cmd = Command::new(program);
	cmd.current_dir(current_dir)
		.args(args)
		.stdin(Stdio::inherit())
		.stdout(Stdio::inherit())
		.stderr(Stdio::inherit());

	Ok(cmd.status()?)
}

pub fn run_capture(program: &str, args: &[&str]) -> anyhow::Result<String> {
	let out = Command::new(program).args(args).output()?;
	if !out.status.success() {
		let stderr = String::from_utf8_lossy(&out.stderr).trim().to_string();
		anyhow::bail!(
			"command failed: {} {} ({})",
			program,
			args.join(" "),
			stderr
		);
	}
	Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
}
