import { $ } from 'bun';
import { argv } from 'process';

const command = argv[2];
if (!command) {
	console.error('⚠️  Kein Befehl übergeben.');
	process.exit(1);
}

try {
	const module = await import(`./commands/${command}.ts`);
	if (typeof module.default === 'function') {
		await module.default();
	} else {
		console.error('⚠️  Ungültiger Befehl.');
	}
} catch (err) {
	console.error(`❌ Fehler beim Laden von '${command}':\n`, err);
}
