use std::collections::HashMap;
use std::path::Path;

use serde::Deserialize;

use crate::net;

/// Minimal shape of `GET https://fill.papermc.io/v3/projects/paper`.
#[derive(Debug, Clone, Deserialize)]
struct FillProjectIndex {
	versions: HashMap<String, Vec<String>>,
}

pub(super) fn resolve_paper_version(version: &str) -> anyhow::Result<String> {
	if !looks_like_family_key(version) {
		return Ok(version.to_string());
	}

	let index = net::get_json::<FillProjectIndex>(
		"https://fill.papermc.io/v3/projects/paper",
	)?;

	let versions = index.versions.get(version).ok_or_else(|| {
		anyhow::anyhow!("Unknown Paper version family: {version}")
	})?;

	let best = pick_best_version_for_family(versions).ok_or_else(|| {
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

fn pick_best_version_for_family(versions: &[String]) -> Option<&str> {
	versions
		.iter()
		.find(|v| !v.contains('-'))
		.or_else(|| versions.first())
		.map(|s| s.as_str())
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
	let builds = net::get_json::<Vec<FillBuild>>(&url)?;
	if builds.is_empty() {
		anyhow::bail!("No Paper builds found for {version}");
	}

	let best = pick_best_build(&builds).ok_or_else(|| {
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

	net::download_to_file(&download.url, jar_path)?;
	Ok(())
}

fn pick_best_build(builds: &[FillBuild]) -> Option<&FillBuild> {
	builds
		.iter()
		.filter(|b| b.channel == "STABLE")
		.max_by_key(|b| b.id)
		.or_else(|| builds.iter().max_by_key(|b| b.id))
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn family_key_detection() {
		assert!(looks_like_family_key("1.21"));
		assert!(looks_like_family_key(" 1.21 "));
		assert!(!looks_like_family_key("1.21.11"));
		assert!(!looks_like_family_key("1.21-rc1"));
		assert!(!looks_like_family_key("paper"));
		assert!(!looks_like_family_key(""));
	}

	#[test]
	fn pick_best_version_prefers_non_prerelease() {
		let versions = vec![
			"1.21.11-rc3".to_string(),
			"1.21.11".to_string(),
			"1.21.10".to_string(),
		];
		assert_eq!(pick_best_version_for_family(&versions), Some("1.21.11"));
	}

	#[test]
	fn pick_best_version_falls_back_to_first() {
		let versions = vec!["1.21.11-rc3".to_string()];
		assert_eq!(
			pick_best_version_for_family(&versions),
			Some("1.21.11-rc3")
		);
	}

	#[test]
	fn pick_best_build_prefers_stable_highest_id() {
		let builds = vec![
			FillBuild {
				id: 1,
				channel: "STABLE".to_string(),
				downloads: HashMap::new(),
			},
			FillBuild {
				id: 10,
				channel: "BETA".to_string(),
				downloads: HashMap::new(),
			},
			FillBuild {
				id: 5,
				channel: "STABLE".to_string(),
				downloads: HashMap::new(),
			},
		];

		assert_eq!(pick_best_build(&builds).map(|b| b.id), Some(5));
	}
}
