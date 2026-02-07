//! Small networking helpers used across commands.
//!
//! This module intentionally stays minimal:
//! - blocking IO (fits the CLI model)
//! - no global client state
//! - helpers are pure where possible and tested

use std::io::Read;
use std::path::Path;
use std::time::{Duration, Instant};

use serde::de::DeserializeOwned;

/// Performs a blocking HTTP GET and deserializes the response body as JSON.
///
/// Errors if the server response is not `200 OK` or if the body cannot be
/// deserialized.
pub fn get_json<T: DeserializeOwned>(url: &str) -> anyhow::Result<T> {
	let resp = ureq::get(url).call()?;
	let status = resp.status();
	if status != 200 {
		anyhow::bail!("HTTP {status} for {url}");
	}

	let mut reader = resp.into_body().into_reader();
	let mut buf = Vec::new();
	reader.read_to_end(&mut buf)?;

	let json = serde_json::from_slice::<T>(&buf)?;
	Ok(json)
}

/// Downloads a URL to a file, streaming to disk and showing a simple progress
/// bar when `Content-Length` is available.
pub fn download_to_file(url: &str, out_path: &Path) -> anyhow::Result<()> {
	use std::io::Write;

	let resp = ureq::get(url).call()?;
	let status = resp.status();
	if status != 200 {
		anyhow::bail!("Download failed (HTTP {status})");
	}

	let total_bytes = resp
		.headers()
		.get("content-length")
		.and_then(|v| v.to_str().ok())
		.and_then(|s| s.parse::<u64>().ok());

	let mut reader = resp.into_body().into_reader();
	let mut file = std::fs::File::create(out_path)?;

	let mut downloaded: u64 = 0;
	let mut buf = vec![0_u8; 64 * 1024];

	let mut last_draw = Instant::now()
		.checked_sub(Duration::from_secs(10))
		.unwrap_or_else(Instant::now);

	loop {
		let n = reader.read(&mut buf)?;
		if n == 0 {
			break;
		}

		file.write_all(&buf[..n])?;
		downloaded += n as u64;

		if last_draw.elapsed() >= Duration::from_millis(120) {
			draw_progress(downloaded, total_bytes)?;
			last_draw = Instant::now();
		}
	}

	draw_progress(downloaded, total_bytes)?;
	println!();
	file.flush()?;

	Ok(())
}

fn draw_progress(downloaded: u64, total: Option<u64>) -> anyhow::Result<()> {
	use std::io::Write;

	let mut out = std::io::stdout();

	match total {
		Some(total) if total > 0 => {
			let pct = (downloaded as f64 / total as f64).min(1.0);
			let width = 28;
			let filled = (pct * width as f64).round() as usize;
			let filled = filled.min(width);
			let empty = width.saturating_sub(filled);

			let bar = format!("[{}{}]", "#".repeat(filled), ".".repeat(empty));

			let pct_s = format!("{:>3}%", (pct * 100.0).round() as u64);
			let cur = format_bytes(downloaded);
			let tot = format_bytes(total);

			print!("\r{bar} {pct_s} {cur}/{tot}");
		}
		_ => {
			let cur = format_bytes(downloaded);
			print!("\rDownloading... {cur}");
		}
	}

	out.flush()?;
	Ok(())
}

fn format_bytes(n: u64) -> String {
	const KIB: f64 = 1024.0;
	const MIB: f64 = KIB * 1024.0;
	const GIB: f64 = MIB * 1024.0;

	let n_f = n as f64;
	if n_f >= GIB {
		format!("{:.1}GiB", n_f / GIB)
	} else if n_f >= MIB {
		format!("{:.1}MiB", n_f / MIB)
	} else if n_f >= KIB {
		format!("{:.1}KiB", n_f / KIB)
	} else {
		format!("{n}B")
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn format_bytes_bytes() {
		assert_eq!(format_bytes(0), "0B");
		assert_eq!(format_bytes(999), "999B");
	}

	#[test]
	fn format_bytes_kib() {
		assert_eq!(format_bytes(1024), "1.0KiB");
		assert_eq!(format_bytes(1536), "1.5KiB");
	}

	#[test]
	fn format_bytes_mib() {
		assert_eq!(format_bytes(1024 * 1024), "1.0MiB");
	}

	#[test]
	fn format_bytes_gib() {
		assert_eq!(format_bytes(1024 * 1024 * 1024), "1.0GiB");
	}
}
