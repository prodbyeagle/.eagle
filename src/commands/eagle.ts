import type { CommandDefinition } from './types';

function sleep(ms: number) {
        return new Promise((resolve) => setTimeout(resolve, ms));
}

export const eagleCommand: CommandDefinition = {
        name: 'eagle',
        description: 'Shows a playful animation inspired by the original PowerShell script.',
        run: async (_args, ctx) => {
                const { logger } = ctx;

                const frames = ['🦅', '✨', '🌟', '🦅'];
                process.stdout.write('\n');
                for (let i = 0; i < 12; i++) {
                        const frame = frames[i % frames.length];
                        process.stdout.write(`\r${frame}  eagle was here.`);
                        await sleep(80);
                }
                process.stdout.write('\r   \r');
                logger.success('eagle was here.');
        },
};
