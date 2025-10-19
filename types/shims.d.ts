declare module 'bun' {
        export function $(
                strings: TemplateStringsArray,
                ...values: any[]
        ): {
                text(): Promise<string>;
                quiet(): {
                        text(): Promise<string>;
                };
        };
}

declare module 'chalk' {
        const chalk: any;
        export default chalk;
}

declare module 'prompts' {
        function prompts<T = any>(questions: any, options?: any): Promise<T>;
        export default prompts;
}

declare module 'zod' {
        export const z: any;
}

declare module 'fs' {
        export function existsSync(path: string): boolean;
        export function rmSync(path: string, options?: any): void;
        export function mkdirSync(path: string, options?: any): void;
        export function readFileSync(path: string, encoding?: any): string;
        export function writeFileSync(path: string, data: any, encoding?: any): void;
        export function readdirSync(path: string, options?: any): any[];
        export function cpSync(src: string, dest: string, options?: any): void;
        export function mkdtempSync(prefix: string): string;
        export function statSync(path: string): { isDirectory(): boolean };
        export function copyFileSync(src: string, dest: string): void;
        export function appendFileSync(path: string, data: any): void;
}

declare module 'fs/promises' {
        export function readFile(path: string, encoding?: any): Promise<string>;
}

declare module 'path' {
        export function join(...parts: string[]): string;
        export function basename(path: string): string;
        export const sep: string;
}

declare module 'os' {
        export function tmpdir(): string;
        export function homedir(): string;
}

declare var process: {
        argv: string[];
        cwd(): string;
        exit(code?: number): never;
        env: Record<string, string | undefined>;
        chdir(directory: string): void;
        stdout: { write(data: string): void };
        platform: string;
};

declare var Bun: {
        env: Record<string, string | undefined>;
        file(path: string): { text(): Promise<string> };
        write(path: string, data: any): Promise<void>;
};

declare var console: {
        log: (...args: any[]) => void;
        error: (...args: any[]) => void;
};

declare const Buffer: {
        from(data: ArrayBuffer | string): any;
};
