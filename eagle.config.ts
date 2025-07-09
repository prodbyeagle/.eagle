export type LogLevel = 'silent' | 'error' | 'warn' | 'info' | 'debug';

export interface EagleConfig {
	devMode: boolean;
	hideLogs: boolean;
	version: string;

	/**
	 * Logging level to control verbosity.
	 */
	logLevel: LogLevel;

	/**
	 * Default directory for projects.
	 */
	defaultProjectDir: string;

	/**
	 * Number of retry attempts for network calls.
	 */
	retryAttempts: number;

	/**
	 * Timeout in milliseconds for network requests.
	 */
	requestTimeoutMs: number;
}

export const config: EagleConfig = {
	devMode: true,
	hideLogs: false,
	version: '3.0.0',

	logLevel: 'info',
	defaultProjectDir: 'C:/eagle',

	retryAttempts: 3,
	requestTimeoutMs: 10_000,
};
