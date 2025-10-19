import { $ } from 'bun';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import type { CommandDefinition } from './types';

const REPO_URL = 'https://github.com/prodbyeagle/cord';
const REPO_NAME = 'Vencord';

export const eaglecordCommand: CommandDefinition = {
        name: 'eaglecord',
        aliases: ['e', 'eaglecord:dev', 'e:dev'],
        description: 'Downloads and injects the EagleCord fork of Vencord.',
        usage: 'eaglecord [--re]',
        run: async (args, ctx) => {
                const { logger, invokedAs } = ctx;
                const reinstallFlag =
                        args.includes('--re') ||
                        args.includes('-r') ||
                        invokedAs.toLowerCase().endsWith(':dev');

                const repoDir = join(process.env.APPDATA ?? '', 'EagleCord', REPO_NAME);

                try {
                        logger.info('Checking for Bun runtime...');
                        const version = await $`bun --version`.quiet().text();
                        logger.success(`Bun is installed (v${version.trim()})`);
                } catch {
                        logger.warn('Bun not found. Installing Bun...');
                        try {
                                await $`powershell -c "irm bun.sh/install.ps1 | iex"`;
                        } catch (error) {
                                logger.error('Failed to install Bun automatically.', error);
                                return;
                        }
                }

                if (reinstallFlag && existsSync(repoDir)) {
                        logger.warn('Removing existing repo directory for reinstall...');
                        await $`rm -rf ${repoDir}`;
                }

                if (existsSync(repoDir)) {
                        process.chdir(repoDir);
                        const localHash = await $`git rev-parse HEAD`.text();
                        const remoteHashRaw = await $`git ls-remote ${REPO_URL} HEAD`.text();
                        const remoteHash = remoteHashRaw.split('\t')[0];

                        if (localHash.trim() === remoteHash?.trim()) {
                                logger.info(`Repo is up-to-date (commit: ${localHash.trim()})`);
                        } else {
                                logger.warn('Updating to latest commit...');
                                await $`git fetch origin`;
                                await $`git reset --hard origin/main`;
                        }
                } else {
                        const targetDir = join(process.env.APPDATA ?? '', 'EagleCord');
                        if (!existsSync(targetDir)) {
                                mkdirSync(targetDir, { recursive: true });
                        }

                        logger.warn('Cloning fresh copy of repo...');
                        await $`git clone ${REPO_URL} ${repoDir}`;
                        process.chdir(repoDir);
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
                } catch (error) {
                        logger.error('Failed during inject step.', error);
                        return;
                } finally {
                        process.chdir(process.env.HOME ?? process.cwd());
                }

                logger.info('🎉 Vencord installation complete.');
        },
};
