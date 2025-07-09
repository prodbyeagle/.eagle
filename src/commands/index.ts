import { createProjectCommand } from './create-project';
import { eaglecordCommand } from './eagle-cord';

export const commands: Record<string, (args: string[]) => any> = {
	eagleCord: eaglecordCommand,
	create: createProjectCommand,
};
