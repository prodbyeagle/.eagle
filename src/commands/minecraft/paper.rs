use std::collections::HashMap;
use std::path::Path;

use serde::Deserialize;

use super::http;

#[derive(Debug, Clone, Deserialize)]
struct FillProjectIndex {
	versions: HashMap<String, Vec<String>>,
}

pub(super) fn resolve_paper_version(version: &str) -> anyhow::Result<String> {
	if !looks_like_family_key(version) {
		return Ok(version.to_string());
	}

	let index = http::get_json::<FillProjectIndex>(
		"https://fill.papermc.io/v3/projects/paper",
	)?;

	let versions = index.versions.get(version).ok_or_else(|| {
		anyhow::anyhow!("Unknown Paper version family: {version}")
	})?;

	let best = versions
		.iter()
		.find(|v| !v.contains('-'))
		.or_else(|| versions.first())
		.ok_or_else(|| {
			anyhow::anyhow!("No versions found for Paper family: {version}")
		})?;

	Ok(best.to_string())
}

fn looks_like_family_key(s: &str) -> bool {
	let s = s.trim();
	if s.is_empty() || s.contains('-') {
		return false;
	}

	let parts: Vec<&str> = s.split('.').collect();
	if parts.len() != 2 {
		return false;
	}

	parts
		.iter()
		.all(|p| !p.is_empty() && p.chars().all(|c| c.is_ascii_digit()))
}

#[derive(Debug, Clone, Deserialize)]
struct FillBuild {
	id: u64,
	channel: String,
	downloads: HashMap<String, FillDownload>,
}

#[derive(Debug, Clone, Deserialize)]
struct FillDownload {
	name: String,
	checksums: FillChecksums,
	url: String,
}

#[derive(Debug, Clone, Deserialize)]
struct FillChecksums {
	sha256: String,
}

pub(super) fn download_paper_server(
	version: &str,
	jar_path: &Path,
) -> anyhow::Result<()> {
	println!("Downloading Paper {version}...");

	let url = format!(
		"https://fill.papermc.io/v3/projects/paper/versions/{version}/builds"
	);
	let builds = http::get_json::<Vec<FillBuild>>(&url)?;
	if builds.is_empty() {
		anyhow::bail!("No Paper builds found for {version}");
	}

	let best = builds
		.iter()
		.filter(|b| b.channel == "STABLE")
		.max_by_key(|b| b.id)
		.or_else(|| builds.iter().max_by_key(|b| b.id))
		.ok_or_else(|| {
			anyhow::anyhow!("No Paper builds found for {version}")
		})?;

	let download = best
		.downloads
		.get("server:default")
		.ok_or_else(|| anyhow::anyhow!("Missing Paper server download"))?;

	println!(
		"Build {}: {} (sha256 {})",
		best.id, download.name, download.checksums.sha256
	);

	http::download_file(&download.url, jar_path)?;
	Ok(())
}
