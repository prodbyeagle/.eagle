use std::path::{Path, PathBuf};

#[derive(Debug, Clone)]
pub struct Context {
	pub exe_path: PathBuf,
	pub exe_dir: PathBuf,
	pub version: &'static str,
	pub repo_url: &'static str,
}

impl Context {
	pub fn new() -> anyhow::Result<Self> {
		let exe_path = std::env::current_exe()?;
		let exe_dir = exe_path
			.parent()
			.map(Path::to_path_buf)
			.unwrap_or_else(|| PathBuf::from("."));

		Ok(Self {
			exe_path,
			exe_dir,
			version: env!("CARGO_PKG_VERSION"),
			repo_url: "https://github.com/prodbyeagle/eaglePowerShell",
		})
	}
}
