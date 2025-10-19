import type { CommandDefinition } from './types';

export const helpCommand: CommandDefinition = {
        name: 'help',
        aliases: ['--h', 'h'],
        description: 'Displays this help message.',
        usage: 'help [command]',
        run: async (args, ctx) => {
                const { logger, commandList } = ctx;

                if (args[0]) {
                        const query = args[0].toLowerCase();
                        const match = commandList.find((command) =>
                                command.name === query ||
                                command.aliases?.some((alias) => alias.toLowerCase() === query)
                        );

                        if (!match) {
                                logger.error(`Unknown command '${args[0]}'.`);
                                return;
                        }

                        const lines = [
                                `${match.name}${
                                        match.aliases?.length
                                                ? ` (aliases: ${match.aliases.join(', ')})`
                                                : ''
                                }`,
                                match.description,
                                match.usage ? `Usage: ${match.usage}` : undefined,
                        ].filter(Boolean) as string[];

                        logger.info(lines.join('\n'));
                        return;
                }

                const rows = commandList.map((command) => {
                        const aliasPart = command.aliases?.length
                                ? command.aliases.map((alias) => `(${alias})`).join(' ')
                                : '';
                        return {
                                name: command.name,
                                aliasPart,
                                description: command.description,
                        };
                });

                const longest = rows.reduce(
                        (acc, row) => Math.max(acc, row.name.length + row.aliasPart.length + 1),
                        0
                );

                logger.info('🦅 Eagle CLI — Available Commands\n─────────────────────────────────────────────');
                for (const row of rows) {
                        const label = `${row.name} ${row.aliasPart}`.trim();
                        logger.info(`  ${label.padEnd(longest)} : ${row.description}`);
                }
                logger.info('─────────────────────────────────────────────');
        },
};
