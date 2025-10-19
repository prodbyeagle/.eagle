import { logger } from '../lib/logger';

export async function statusCommand() {
        logger.info('TypeScript rewrite status: ongoing.');
        logger.info(
                'Core CLI commands have been migrated. Contributions are welcome to help complete the remaining modules.'
        );
        logger.info('Run `eagle create` or `eagle eagleCord` to explore the current functionality.');
}
