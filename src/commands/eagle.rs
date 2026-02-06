use std::io::{Write, stdout};
use std::time::Duration;

use clap::{Arg, ArgMatches, Command};

use crate::commands::CommandSpec;
use crate::context::Context;

fn build() -> Command {
	Command::new("eagle")
		.about("Tiny terminal animation (Ctrl+C to stop)")
		.arg(
			Arg::new("delay_ms")
				.long("delay-ms")
				.help("Frame delay in milliseconds")
				.value_parser(clap::value_parser!(u64))
				.required(false),
		)
}

fn run(matches: &ArgMatches, _: &Context) -> anyhow::Result<()> {
	let delay_ms = *matches.get_one::<u64>("delay_ms").unwrap_or(&40);
	let delay = Duration::from_millis(delay_ms);

	let frames = ["( )", " _ ", "( )", " _ "];
	let mut i = 0usize;

	crossterm::terminal::enable_raw_mode()?;
	let _guard = RawModeGuard;

	loop {
		crossterm::execute!(
			stdout(),
			crossterm::terminal::Clear(crossterm::terminal::ClearType::All),
			crossterm::cursor::MoveTo(0, 0),
			crossterm::terminal::SetTitle("eagle")
		)?;

		println!("{}", frames[i % frames.len()]);
		println!();
		println!("Press Ctrl+C to stop.");
		std::thread::sleep(delay);

		i = i.wrapping_add(1);

		if crossterm::event::poll(Duration::from_millis(1))?
			&& let crossterm::event::Event::Key(key) = crossterm::event::read()?
			&& key.code == crossterm::event::KeyCode::Char('c')
			&& key
				.modifiers
				.contains(crossterm::event::KeyModifiers::CONTROL)
		{
			break;
		}

		stdout().flush()?;
	}

	Ok(())
}

struct RawModeGuard;

impl Drop for RawModeGuard {
	fn drop(&mut self) {
		let _ = crossterm::terminal::disable_raw_mode();
	}
}

inventory::submit! {
	CommandSpec {
		command: build,
		run,
	}
}
