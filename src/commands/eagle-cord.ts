import { $ } from 'bun';
import { existsSync } from 'fs';
import { join } from 'path';
import { logger } from '../lib/logger';

export async function eaglecordCommand(args: string[]) {
	const re = args.includes('--re') || args.includes('-r');

	const repoUrl = 'https://github.com/prodbyeagle/cord';
	const repoName = 'Vencord';
	const vencordTempDir = join(process.env.APPDATA ?? '', 'EagleCord');
	const vencordCloneDir = join(vencordTempDir, repoName);

	try {
		logger.info('Checking for Bun runtime...');
		const version = await $`bun --version`.quiet().text();
		logger.success(`Bun is installed (v${version.trim()})`);
	} catch {
		logger.warn('Bun not found. Installing Bun...');
		await $`powershell -c "irm bun.sh/install.ps1 | iex"`;
	}

	if (re && existsSync(vencordCloneDir)) {
		logger.warn('Removing existing repo directory for reinstall...');
		await $`rm -rf ${vencordCloneDir}`;
	}

	if (existsSync(vencordCloneDir)) {
		process.chdir(vencordCloneDir);
		const localHash = await $`git rev-parse HEAD`.text();
		const remoteHashRaw = await $`git ls-remote ${repoUrl} HEAD`.text();
		const remoteHash = remoteHashRaw.split('\t')[0];

		if (localHash.trim() === remoteHash?.trim()) {
			logger.info(`Repo is up-to-date (commit: ${localHash.trim()})`);
		} else {
			logger.warn('Updating to latest commit...');
			await $`git fetch origin`;
			await $`git reset --hard origin/main`;
		}
	} else {
		logger.warn('Cloning fresh copy of repo...');
		await $`git clone ${repoUrl} ${vencordCloneDir}`;
		process.chdir(vencordCloneDir);
	}

	if (existsSync('./dist')) {
		logger.info('Cleaning dist folder...');
		await $`rm -rf ./dist`;
	}

	logger.warn('Installing dependencies...');
	await $`bun install`;
	logger.success('Dependency installation complete.');

	try {
		logger.warn('Injecting EagleCord...');
		await $`bun run build`;
		await $`bun inject`;
		logger.success('EagleCord injected successfully.');
	} catch (err) {
		logger.error('Failed during inject step', err);
		return;
	}

	process.chdir(process.env.HOME ?? process.cwd());
	logger.info('🎉 Vencord installation complete.');
}
