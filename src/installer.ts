#!/usr/bin/env bun
import {
	mkdirSync,
	writeFileSync,
	existsSync,
	copyFileSync,
	readdirSync,
	statSync,
	rmSync,
	appendFileSync,
} from 'fs';
import { join, sep } from 'path';
import { logger } from './lib/logger';
import { $ } from 'bun';

const scriptPath = 'C:/Scripts';
const corePath = join(scriptPath, 'core');

const eagleUrl =
	'https://raw.githubusercontent.com/prodbyeagle/.eagle/main/eagle.ts';
const coreBaseUrl =
	'https://raw.githubusercontent.com/prodbyeagle/.eagle/main/core';

const eagleLocalSource = `${process.cwd()}/eagle.ts`;
const coreLocalSource = `${process.cwd()}/core`;
const eagleTargetFile = join(scriptPath, 'eagle.ts');

const isDevMode = process.argv.includes('--dev');

function logStep(msg: string) {
	logger.info(`📥 ${msg}`);
}

function logSuccess(msg: string) {
	logger.success(`✅ ${msg}`);
}

function ensureDir(path: string) {
	if (!existsSync(path)) {
		mkdirSync(path, { recursive: true });
		logger.info(`Created folder: ${path}`);
	}
}

async function downloadFile(url: string, dest: string) {
	try {
		const res = await fetch(url);
		if (!res.ok) throw new Error(`Failed to download ${url}`);
		const data = await res.text();
		writeFileSync(dest, data);
	} catch (err) {
		logger.error(`Couldn't download ${url}`, err);
		process.exit(1);
	}
}

function copyDirRecursive(src: string, dest: string) {
	for (const file of readdirSync(src)) {
		const srcPath = join(src, file);
		const destPath = join(dest, file);
		if (statSync(srcPath).isDirectory()) {
			ensureDir(destPath);
			copyDirRecursive(srcPath, destPath);
		} else {
			copyFileSync(srcPath, destPath);
		}
	}
}

async function getCoreFiles() {
	const coreFiles = ['create-project.ts', 'eagle-cord.ts'];

	for (const file of coreFiles) {
		logStep(`Downloading helper file: ${file}`);
		await downloadFile(`${coreBaseUrl}/${file}`, join(corePath, file));
	}
}

async function setupAlias() {
	const powershellProfile = process.env.USERPROFILE
		? join(
				process.env.USERPROFILE,
				'Documents',
				'PowerShell',
				'Microsoft.PowerShell_profile.ts'
		  )
		: null;

	if (!powershellProfile) return;

	const aliasLine = `Set-Alias eagle "${eagleTargetFile}"`;

	if (!existsSync(powershellProfile)) {
		writeFileSync(powershellProfile, `${aliasLine}\n`);
		logSuccess('Created PowerShell profile with Eagle alias.');
	} else {
		const content = Bun.file(powershellProfile).text();
		if (!(await content).includes(aliasLine)) {
			appendFileSync(powershellProfile, `\n${aliasLine}\n`);
			logSuccess("✔ You can now run 'eagle' from PowerShell.");
		} else {
			logger.info('Alias already exists, skipping.');
		}
	}
}

function setupPathEnv() {
	const userPath = Bun.env['Path'] || process.env['Path'];
	if (!userPath?.includes(scriptPath)) {
		const updatedPath = `${userPath};${scriptPath}`;
		$`setx Path "${updatedPath}" > nul`;
		logSuccess('Added Eagle to system PATH.');
	} else {
		logger.info('Eagle path already in PATH.');
	}
}

// Main
logger.info('🚀 Starting Eagle installer...');

ensureDir(scriptPath);
ensureDir(corePath);

if (isDevMode) {
	logger.warn('Installing from local dev sources...');
	copyFileSync(eagleLocalSource, eagleTargetFile);
	copyDirRecursive(coreLocalSource, corePath);
} else {
	logStep('Downloading main eagle.ts...');
	await downloadFile(eagleUrl, eagleTargetFile);

	logStep('Downloading core helpers...');
	await getCoreFiles();
}

await setupAlias();
setupPathEnv();

logger.success('\n🎉 Eagle installed successfully!');
logger.info('🧠 Please restart PowerShell to use `eagle`.');
