use std::path::Path;

use serde::Deserialize;

use super::http;

#[derive(Debug, Clone, Deserialize)]
struct LoaderCombo {
	loader: LoaderPart,
	installer: InstallerPart,
}

#[derive(Debug, Clone, Deserialize)]
struct LoaderPart {
	version: String,
	#[serde(default)]
	stable: Option<bool>,
}

#[derive(Debug, Clone, Deserialize)]
struct InstallerPart {
	version: String,
	#[serde(default)]
	stable: Option<bool>,
}

pub(super) fn download_fabric_server(
	version: &str,
	jar_path: &Path,
) -> anyhow::Result<()> {
	println!("Downloading Fabric {version}...");

	let url = format!("https://meta.fabricmc.net/v2/versions/loader/{version}");
	let combos = http::get_json::<Vec<LoaderCombo>>(&url)?;
	if combos.is_empty() {
		anyhow::bail!("No Fabric loader versions found for {version}");
	}

	let best = combos
		.iter()
		.find(|c| {
			c.loader.stable.unwrap_or(true)
				&& c.installer.stable.unwrap_or(true)
		})
		.or_else(|| combos.first())
		.ok_or_else(|| anyhow::anyhow!("No Fabric loader versions found"))?;

	let loader = &best.loader.version;
	let installer = &best.installer.version;

	let url = format!(
		"https://meta.fabricmc.net/v2/versions/loader/{version}/{loader}/{installer}/server/jar"
	);
	http::download_file(&url, jar_path)?;
	Ok(())
}
