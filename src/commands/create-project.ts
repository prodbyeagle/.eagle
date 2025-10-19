import { $ } from 'bun';
import { existsSync, rmSync } from 'fs';
import { join } from 'path';
import prompts from 'prompts';
import { z } from 'zod';
import type { CommandDefinition } from './types';

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

type TemplateKey = keyof typeof TEMPLATE_MAP;

export const createProjectCommand: CommandDefinition = {
        name: 'create',
        aliases: ['c'],
        description: 'Bootstraps a new project from a template repository.',
        usage: 'create [name] [template]',
        run: async (rawArgs, ctx) => {
                const { logger } = ctx;

                const inputSchema = z
                        .tuple([z.string().optional(), z.string().optional()])
                        .transform(([name, template]: [string | undefined, string | undefined]) => ({
                                name,
                                template,
                        }));

                const { name: nameArg, template: templateArg } = inputSchema.parse(rawArgs);

                const response = await prompts(
                        [
                                {
                                        type: nameArg ? null : 'text',
                                        name: 'name',
                                        message: '📝 Enter project name',
                                        validate: (val: string) =>
                                                val.trim().length > 0 || 'Project name required',
                                },
                                {
                                        type: templateArg ? null : 'select',
                                        name: 'template',
                                        message: '📌 Choose a template',
                                        choices: (Object.keys(TEMPLATE_MAP) as TemplateKey[]).map((t) => ({
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

                const name = nameArg || (response as { name: string }).name;
                const template = (templateArg || (response as { template: TemplateKey }).template) as TemplateKey;

                if (!TEMPLATE_MAP[template]) {
                        logger.error(
                                `Invalid template: '${template}'. Allowed: ${(Object.keys(TEMPLATE_MAP) as TemplateKey[]).join(
                                        ', '
                                )}`
                        );
                        process.exit(1);
                }

                const { repo, targetRoot } = TEMPLATE_MAP[template];
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

                const gitFolder = join(projectPath, '.git');
                if (existsSync(gitFolder)) {
                        rmSync(gitFolder, { recursive: true, force: true });
                        logger.info('🧹 Removed .git folder');
                }

                const originalCwd = process.cwd();
                try {
                        process.chdir(projectPath);
                        logger.info('📦 Updating / Installing packages...');
                        await $`bun update --latest`;
                        logger.success('✅ Bun packages updated successfully.');
                } catch (error) {
                        logger.error('❌ Failed to update Bun packages.', error);
                } finally {
                        process.chdir(originalCwd);
                }

                logger.success(`🎉 Project '${name}' created at ${projectPath}`);
        },
};
