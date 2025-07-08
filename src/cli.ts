#!/usr/bin/env bun
import { argv, exit } from 'process';
import { commands } from './commands';
import { logger, setLogLevel } from './lib/logger';

// Optional: parse global flags like --verbose
const [, , rawCommand, ...restArgs] = argv;

const globalFlags = restArgs.filter((arg) => arg.startsWith('--'));
const args = restArgs.filter((arg) => !arg.startsWith('--'));

if (globalFlags.includes('--silent')) setLogLevel('silent');
else if (globalFlags.includes('--debug')) setLogLevel('debug');
else setLogLevel('info');

if (!rawCommand || rawCommand === 'help') {
	logger.info('🦅 Eagle CLI\nAvailable commands:\n');
	for (const cmd of Object.keys(commands)) {
		logger.info(`  • ${cmd}`);
	}
	exit(0);
}

const command = commands[rawCommand];
if (!command) {
	logger.error(
		`Unknown command '${rawCommand}'. Run 'eagle help' for options.`
	);
	exit(1);
}

try {
	await command(args);
} catch (err) {
	logger.error('Command failed.', err);
	exit(1);
}
