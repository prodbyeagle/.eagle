import { createProjectCommand } from './create-project';
import { eagleCommand } from './eagle';
import { eaglecordCommand } from './eagle-cord';
import { helpCommand } from './help';
import { minecraftCommand } from './minecraft';
import { spicetifyCommand } from './spicetify';
import type { CommandDefinition } from './types';
import { uninstallCommand } from './uninstall';
import { updateCommand } from './update';
import { versionCommand } from './version';

export const commandList: CommandDefinition[] = [
        helpCommand,
        spicetifyCommand,
        eaglecordCommand,
        createProjectCommand,
        updateCommand,
        uninstallCommand,
        versionCommand,
        minecraftCommand,
        eagleCommand,
];

const commandLookup = new Map<string, CommandDefinition>();
for (const command of commandList) {
        commandLookup.set(command.name.toLowerCase(), command);
        if (command.aliases) {
                for (const alias of command.aliases) {
                        commandLookup.set(alias.toLowerCase(), command);
                }
        }
}

export interface CommandResolution {
        command: CommandDefinition;
        invokedAs: string;
}

export function resolveCommand(name: string): CommandResolution | null {
        const normalized = name.toLowerCase();
        const command = commandLookup.get(normalized);
        if (!command) {
                return null;
        }
        return { command, invokedAs: name };
}
