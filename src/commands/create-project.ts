import { $ } from 'bun';
import { join } from 'path';
import { existsSync, rmSync } from 'fs';
import prompts from 'prompts';
import { z } from 'zod';
import { logger } from '../lib/logger';

const TEMPLATE_MAP = {
	discord: {
		repo: 'https://github.com/prodbyeagle/discord-template.git',
		targetRoot: 'D:/VSCode/2025/Discord',
	},
	next: {
		repo: 'https://github.com/prodbyeagle/next-template.git',
		targetRoot: 'D:/VSCode/2025/Frontend',
	},
} as const;

export async function createProjectCommand(rawArgs: string[]) {
	const inputSchema = z
		.tuple([z.string().optional(), z.string().optional()])
		.transform(([name, template]) => ({ name, template }));

	const { name: nameArg, template: templateArg } = inputSchema.parse(rawArgs);

	const response = await prompts(
		[
			{
				type: nameArg ? null : 'text',
				name: 'name',
				message: '📝 Enter project name',
				validate: (val) =>
					val.trim().length > 0 || 'Project name required',
			},
			{
				type: templateArg ? null : 'select',
				name: 'template',
				message: '📌 Choose a template',
				choices: Object.keys(TEMPLATE_MAP).map((t) => ({
					title: t,
					value: t,
				})),
			},
		],
		{
			onCancel: () => {
				logger.warn('Project creation cancelled.');
				process.exit(0);
			},
		}
	);

	const name = nameArg || response.name;
	const template = templateArg || response.template;

	if (!TEMPLATE_MAP[template as keyof typeof TEMPLATE_MAP]) {
		logger.error(
			`Invalid template: '${template}'. Allowed: ${Object.keys(
				TEMPLATE_MAP
			).join(', ')}`
		);
		process.exit(1);
	}

	const { repo, targetRoot } =
		TEMPLATE_MAP[template as keyof typeof TEMPLATE_MAP];
	const projectPath = join(targetRoot, name);

	if (existsSync(projectPath)) {
		logger.warn(`⚠️ Project '${name}' already exists at ${projectPath}`);
		return;
	}

	logger.info(`📁 Creating new '${template}' project: ${name}`);
	await $`git clone ${repo} ${projectPath}`;

	if (!existsSync(projectPath)) {
		logger.error('❌ Git clone failed.');
		return;
	}

	// Clean .git
	const gitFolder = join(projectPath, '.git');
	if (existsSync(gitFolder)) {
		rmSync(gitFolder, { recursive: true, force: true });
		logger.info('🧹 Removed .git folder');
	}

	// Install/Update
	try {
		process.chdir(projectPath);
		logger.info('📦 Updating / Installing packages...');
		await $`bun update --latest`;
		logger.success('✅ Bun packages updated successfully.');
	} catch (err) {
		logger.error('❌ Failed to update Bun packages.', err);
	}

	logger.success(`🎉 Project '${name}' created at ${projectPath}`);
}
