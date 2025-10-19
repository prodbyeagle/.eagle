import { $ } from 'bun';
import { existsSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'fs';
import { join } from 'path';
import prompts from 'prompts';
import type { CommandDefinition } from './types';

const SCRIPTS_ROOT = 'C:/Scripts';
const SCRIPT_FILE = 'eagle.ps1';
const CORE_DIR = 'core';
const EAGLE_DIR = 'eagle';

async function resolveProfilePath() {
        try {
                const result = await $`powershell -NoProfile -Command $PROFILE`.text();
                return result.trim();
        } catch {
                return null;
        }
}

function removePath(target: string) {
        if (!existsSync(target)) {
                return false;
        }
        rmSync(target, { recursive: true, force: true });
        return true;
}

export const uninstallCommand: CommandDefinition = {
        name: 'uninstall',
        aliases: ['rem'],
        description: 'Removes the legacy PowerShell installation and cleans aliases.',
        run: async (_args, ctx) => {
                const { logger } = ctx;

                if (process.platform !== 'win32') {
                        logger.warn('Uninstall is only supported on Windows.');
                        return;
                }

                const response = await prompts({
                        type: 'confirm',
                        name: 'confirm',
                        message: '🛑 You are about to uninstall eagle. Continue?',
                        initial: false,
                });

                if (!response.confirm) {
                        logger.error('❌ Uninstallation cancelled.');
                        return;
                }

                logger.info('Uninstalling eagle...');

                try {
                        const eaglePath = join(SCRIPTS_ROOT, SCRIPT_FILE);
                        if (removePath(eaglePath)) {
                                logger.success(`✅ Removed ${SCRIPT_FILE} from ${eaglePath}`);
                        } else {
                                logger.warn(`ℹ ${SCRIPT_FILE} not found at ${eaglePath}`);
                        }

                        const corePath = join(SCRIPTS_ROOT, CORE_DIR);
                        if (removePath(corePath)) {
                                logger.success(`✅ Removed core folder from ${corePath}`);
                        } else {
                                logger.warn(`ℹ core folder not found at ${corePath}`);
                        }

                        const eagleFolder = join(SCRIPTS_ROOT, EAGLE_DIR);
                        if (removePath(eagleFolder)) {
                                logger.success(`✅ Removed eagle folder from ${eagleFolder}`);
                        } else {
                                logger.warn(`ℹ eagle folder not found at ${eagleFolder}`);
                        }

                        const profilePath = await resolveProfilePath();
                        if (profilePath && existsSync(profilePath)) {
                                const profileContent = readFileSync(profilePath, 'utf8')
                                        .split(/\r?\n/)
                                        .filter((line) => !line.includes('Set-Alias eagle'))
                                        .join('\n');
                                writeFileSync(profilePath, profileContent, 'utf8');
                                logger.success('✅ Removed alias from PowerShell profile');
                        }

                        if (existsSync(SCRIPTS_ROOT) && readdirSync(SCRIPTS_ROOT).length === 0) {
                                rmSync(SCRIPTS_ROOT, { recursive: true, force: true });
                                logger.success(`✅ Removed empty folder ${SCRIPTS_ROOT}`);
                        }

                        logger.success('🎉 Uninstallation complete.');
                } catch (error) {
                        logger.error('❌ Failed to uninstall eagle.', error);
                }
        },
};
