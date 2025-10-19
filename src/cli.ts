#!/usr/bin/env bun
import { commandList, resolveCommand } from './commands';
import { logger, setLogLevel } from './lib/logger';

const argsList = [...process.argv];
const rawCommand = argsList[2];
const restArgs = argsList.slice(3);

const recognizedGlobals = new Set(['--silent', '--debug']);
const globalFlags = restArgs.filter((arg: string) => recognizedGlobals.has(arg));
const args = restArgs.filter((arg: string) => !recognizedGlobals.has(arg));

if (globalFlags.includes('--silent')) setLogLevel('silent');
else if (globalFlags.includes('--debug')) setLogLevel('debug');
else setLogLevel('info');

if (!rawCommand) {
        const helpCommand = commandList.find((command) => command.name === 'help');
        if (helpCommand) {
                await helpCommand.run([], { logger, commandList, invokedAs: 'help' });
        }
        process.exit(0);
}

const resolution = resolveCommand(rawCommand);
if (!resolution) {
        logger.error(`Unknown command '${rawCommand}'. Run 'eagle help' for options.`);
        process.exit(1);
}

const { command, invokedAs } = resolution;
let commandArgs = args;
if (command.name === 'eaglecord' && invokedAs.toLowerCase().includes(':dev')) {
        commandArgs = [...commandArgs, '--re'];
}

try {
        await command.run(commandArgs, {
                logger,
                commandList,
                invokedAs,
        });
} catch (err) {
        logger.error('Command failed.', err);
        process.exit(1);
}
