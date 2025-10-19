import { readFile } from 'fs/promises';
import { join } from 'path';
import type { CommandDefinition } from './types';

function getPackageJsonPath() {
        return join(process.cwd(), 'package.json');
}

async function readVersion() {
        const pkgRaw = await readFile(getPackageJsonPath(), 'utf8');
        const pkg = JSON.parse(pkgRaw) as { version?: string; name?: string };
        return {
                name: pkg.name ?? 'eagle',
                version: pkg.version ?? '0.0.0',
        };
}

export const versionCommand: CommandDefinition = {
        name: 'version',
        aliases: ['v'],
        description: 'Displays the current version of the eagle CLI.',
        run: async (_args, ctx) => {
                const { logger } = ctx;
                try {
                        const { name, version } = await readVersion();
                        logger.info('');
                        logger.info('🦅 eagle');
                        logger.info('────────────────────────────');
                        logger.info(`Version        : v${version}`);
                        logger.info('Repository     : https://github.com/prodbyeagle/eagle');
                        logger.info('────────────────────────────');
                } catch (error) {
                        logger.error('Unable to read version information.', error);
                }
        },
};
