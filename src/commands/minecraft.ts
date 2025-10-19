import { $ } from 'bun';
import { existsSync, readdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import prompts from 'prompts';
import type { CommandDefinition } from './types';

const DEFAULT_RAM_MB = 8192;
const SERVERS_ROOT = join(homedir(), 'Documents', 'mc-servers');

function parseRam(args: string[]) {
        const flagIndex = args.findIndex((arg) => arg === '--ram' || arg === '-m');
        if (flagIndex >= 0) {
                const value = Number(args[flagIndex + 1]);
                if (Number.isFinite(value) && value > 0) {
                        return value;
                }
        }

        const inline = args.find((arg) => arg.startsWith('--ram='));
        if (inline) {
                const value = Number(inline.split('=')[1]);
                if (Number.isFinite(value) && value > 0) {
                        return value;
                }
        }

        return DEFAULT_RAM_MB;
}

function listServers() {
        if (!existsSync(SERVERS_ROOT)) {
                return [] as { name: string; path: string }[];
        }

        return readdirSync(SERVERS_ROOT, { withFileTypes: true })
                .filter((entry) => entry.isDirectory())
                .map((entry) => ({
                        name: entry.name,
                        path: join(SERVERS_ROOT, entry.name),
                }))
                .filter(({ path }) => existsSync(join(path, 'server.jar')));
}

export const minecraftCommand: CommandDefinition = {
        name: 'minecraft',
        aliases: ['m'],
        description: 'Starts a selected Minecraft server with tuned JVM flags.',
        usage: 'minecraft [serverName] [--ram <mb>]',
        run: async (args, ctx) => {
                const { logger } = ctx;

                if (!existsSync(SERVERS_ROOT)) {
                        logger.error(`oh. ich habe ${SERVERS_ROOT} nicht gefunden.`);
                        logger.info('stelle sicher das du den ordner erstellt hast, und ein minecraft server vorhanden ist.');
                        return;
                }

                const servers = listServers();
                if (!servers.length) {
                        logger.error('oh. ich finde keinen server im mc-servers ordner.');
                        logger.info("stelle sicher das du eine 'server.jar' im ordner hast.");
                        return;
                }

                const nonFlagArg = args.find((arg) => !arg.startsWith('--') && !arg.startsWith('-'));
                let selected = nonFlagArg
                        ? servers.find((server) => server.name.toLowerCase() === nonFlagArg.toLowerCase())
                        : undefined;

                if (!selected) {
                        if (servers.length === 1) {
                                selected = servers[0];
                        } else {
                                const response = await prompts({
                                        type: 'select',
                                        name: 'server',
                                        message: 'wähle einen minecraft server aus den du starten willst',
                                        choices: servers.map((server) => ({
                                                title: server.name,
                                                value: server,
                                        })),
                                });

                                if (!response.server) {
                                        logger.warn('Server start cancelled.');
                                        return;
                                }

                                selected = response.server as { name: string; path: string };
                        }
                }

                if (!selected) {
                        logger.error('Kein Server ausgewählt.');
                        return;
                }

                const jarPath = join(selected.path, 'server.jar');
                if (!existsSync(jarPath)) {
                        logger.error(`oh. ich finde keinen server im ${selected.path} ordner.`);
                        logger.info("stelle sicher das du eine 'server.jar' im ordner hast.");
                        return;
                }

                const ramMB = parseRam(args);
                logger.info(`ich starte ${selected.path} mit ${ramMB}mb ram...`);

                const previousCwd = process.cwd();
                try {
                        process.chdir(selected.path);
                        await $`java -Xmx${ramMB}M -Xms${ramMB}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Daikars.new.flags=true -Dusing.aikars.flags=https://mcutils.com -jar ${jarPath} nogui`;
                        logger.success('server gestoppt.');
                } catch (error) {
                        logger.error('Fehler beim starten des Servers.', error);
                } finally {
                        process.chdir(previousCwd);
                }
        },
};
