import { $ } from 'bun';
import type { CommandDefinition } from './types';

const INSTALL_URL = 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1';

export const spicetifyCommand: CommandDefinition = {
        name: 'spicetify',
        aliases: ['s'],
        description: 'Installs the Spicetify CLI using the official installer.',
        run: async (_args, ctx) => {
                const { logger } = ctx;

                if (process.platform !== 'win32') {
                        logger.warn('Spicetify installation is only supported on Windows.');
                        return;
                }

                logger.info('🎵 Installing Spicetify...');
                logger.info(`🌐 Downloading installer from ${INSTALL_URL}`);

                try {
                        await $`powershell -NoProfile -Command Invoke-WebRequest -UseBasicParsing -Uri ${INSTALL_URL} | Invoke-Expression`;
                        logger.success('✅ Spicetify installed successfully!');
                } catch (error) {
                        logger.error('❌ Failed to install Spicetify.', error);
                }
        },
};
