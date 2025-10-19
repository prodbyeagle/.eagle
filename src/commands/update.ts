import { $ } from 'bun';
import {
        cpSync,
        existsSync,
        mkdtempSync,
        readFileSync,
        readdirSync,
        rmSync,
        statSync,
        writeFileSync,
} from 'fs';
import { join, basename } from 'path';
import { tmpdir } from 'os';
import type { CommandDefinition } from './types';

const REMOTE_ZIP_URL =
        'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip';
const LOCAL_ROOT = 'C:/Scripts';
const SCRIPT_NAME = 'eagle.ps1';
const CORE_FOLDER_NAME = 'core';

function extractVersion(content: string) {
        const match = content.match(/\$scriptVersion\s*=\s*"([^"]+)"/);
        return match?.[1] ?? null;
}

function compareVersions(a: string, b: string) {
        const parse = (value: string) => value.split('.').map((part) => Number(part));
        const left = parse(a);
        const right = parse(b);
        const len = Math.max(left.length, right.length);

        for (let i = 0; i < len; i++) {
                const leftPart = left[i] ?? 0;
                const rightPart = right[i] ?? 0;
                if (leftPart > rightPart) return 1;
                if (leftPart < rightPart) return -1;
        }

        return 0;
}

function findFirst(root: string, matcher: (path: string, isDir: boolean) => boolean): string | null {
        const queue = [root];
        while (queue.length) {
                const current = queue.shift()!;
                const entries = readdirSync(current, { withFileTypes: true });

                for (const entry of entries) {
                        const fullPath = join(current, entry.name);
                        const isDir = entry.isDirectory();
                        if (matcher(fullPath, isDir)) {
                                return fullPath;
                        }

                        if (isDir) {
                                queue.push(fullPath);
                        }
                }
        }

        return null;
}

async function downloadZip(targetPath: string) {
        const response = await fetch(REMOTE_ZIP_URL);
        if (!response.ok) {
                throw new Error(`Failed to download update archive (${response.status}).`);
        }

        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        writeFileSync(targetPath, buffer);
}

export const updateCommand: CommandDefinition = {
        name: 'update',
        aliases: ['u'],
        description: 'Checks for updates to the legacy PowerShell installation and applies them.',
        run: async (_args, ctx) => {
                const { logger } = ctx;

                if (process.platform !== 'win32') {
                        logger.warn('Update is only supported on Windows.');
                        return;
                }

                const localScriptPath = join(LOCAL_ROOT, SCRIPT_NAME);
                if (!existsSync(localScriptPath)) {
                        logger.error('Could not find eagle.ps1 in C:/Scripts. Nothing to update.');
                        return;
                }

                const tempDir = mkdtempSync(join(tmpdir(), 'eagle-update-'));
                const zipPath = join(tempDir, 'update.zip');
                const extractPath = join(tempDir, 'extracted');

                try {
                        logger.info('📦 Checking for updates...');
                        logger.info('⬇ Downloading remote files...');
                        await downloadZip(zipPath);

                        await $`powershell -NoProfile -Command Expand-Archive -Path ${zipPath} -DestinationPath ${extractPath} -Force`;

                        const remoteScriptPath = findFirst(extractPath, (path, isDir) =>
                                !isDir && basename(path).toLowerCase() === SCRIPT_NAME
                        );
                        const remoteCoreFolder = findFirst(extractPath, (path, isDir) =>
                                isDir && basename(path).toLowerCase() === CORE_FOLDER_NAME
                        );

                        if (!remoteScriptPath) {
                                logger.error('Could not locate eagle.ps1 inside the downloaded archive.');
                                return;
                        }

                        const remoteVersion = extractVersion(readFileSync(remoteScriptPath, 'utf8'));
                        const localVersion = extractVersion(readFileSync(localScriptPath, 'utf8'));

                        if (!remoteVersion || !localVersion) {
                                logger.error('Unable to determine script versions for comparison.');
                                return;
                        }

                        if (compareVersions(remoteVersion, localVersion) <= 0) {
                                logger.success(`✅ You already have the latest version (v${localVersion}).`);
                                return;
                        }

                        logger.warn(
                                `🔄 Update available! Local: v${localVersion} → Remote: v${remoteVersion}. Installing update…`
                        );

                        writeFileSync(localScriptPath, readFileSync(remoteScriptPath));
                        logger.success('✅ eagle.ps1 updated successfully.');

                        const localCoreFolder = join(LOCAL_ROOT, CORE_FOLDER_NAME);
                        if (existsSync(localCoreFolder)) {
                                rmSync(localCoreFolder, { recursive: true, force: true });
                                logger.success(`✅ Removed old core folder from ${localCoreFolder}`);
                        }

                        if (remoteCoreFolder && statSync(remoteCoreFolder).isDirectory()) {
                                cpSync(remoteCoreFolder, localCoreFolder, { recursive: true });
                                logger.success('✅ core folder updated successfully.');
                        } else {
                                logger.warn('ℹ No core folder found in the remote update.');
                        }
                } catch (error) {
                        logger.error('❌ Update failed.', error);
                } finally {
                        try {
                                rmSync(tempDir, { recursive: true, force: true });
                        } catch (cleanupError) {
                                logger.debug(`Failed to clean up temporary directory: ${cleanupError}`);
                        }
                }
        },
};
