import { createProjectCommand } from './create-project';
import { eaglecordCommand } from './eagle-cord';
import { statusCommand } from './status';

export const commands: Record<string, (args: string[]) => any> = {
        eagleCord: eaglecordCommand,
        create: createProjectCommand,
        status: statusCommand,
};
