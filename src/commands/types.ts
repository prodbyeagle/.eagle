import type { logger } from '../lib/logger';

export interface CommandContext {
        logger: typeof logger;
        commandList: CommandDefinition[];
        invokedAs: string;
}

export type CommandHandler = (
        args: string[],
        context: CommandContext
) => Promise<void> | void;

export interface CommandDefinition {
        name: string;
        aliases?: string[];
        description: string;
        usage?: string;
        run: CommandHandler;
}
