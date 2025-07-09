import chalk from 'chalk';

type LogLevel = 'silent' | 'info' | 'warn' | 'error' | 'debug' | 'success';

let currentLevel: LogLevel = 'info';

const levels: Record<LogLevel, number> = {
	silent: 0,
	error: 1,
	warn: 2,
	info: 3,
	success: 4,
	debug: 5,
};

export function setLogLevel(level: LogLevel) {
	currentLevel = level;
}

function shouldLog(level: LogLevel) {
	return levels[level] <= levels[currentLevel];
}

//@ts-ignore
function format(label: string, color: chalk.Chalk, message: string) {
	return `${color.bold(label.padEnd(7))} ${message}`;
}

export const logger = {
	info(message: string) {
		if (!shouldLog('info')) return;
		console.log(format('INFO', chalk.blue, message));
	},

	warn(message: string) {
		if (!shouldLog('warn')) return;
		console.log(format('WARN', chalk.yellow, message));
	},

	error(message: string, error?: unknown) {
		if (!shouldLog('error')) return;
		console.error(format('ERROR', chalk.red, message));
		if (error instanceof Error) {
			console.error(chalk.gray(error.stack ?? error.message));
		} else if (error) {
			console.error(chalk.gray(String(error)));
		}
	},

	success(message: string) {
		if (!shouldLog('success')) return;
		console.log(format('SUCCESS', chalk.green, message));
	},

	debug(message: string) {
		if (!shouldLog('debug')) return;
		console.log(format('DEBUG', chalk.magenta, message));
	},
};
