import { defineConfig, fileExists } from "jsr:@yuki-yano/zeno@0.1.0";
import { dirname, join, resolve } from "jsr:@std/path@1.1.0";
type PackageManager = "npm" | "yarn" | "pnpm" | "bun";
const LOCKFILE_HINTS: ReadonlyArray<{
  manager: PackageManager;
  files: readonly string[];
}> = [
  { manager: "bun", files: ["bun.lockb", "bun.lock"] },
  { manager: "pnpm", files: ["pnpm-lock.yaml"] },
  { manager: "yarn", files: ["yarn.lock"] },
  { manager: "npm", files: ["package-lock.json"] },
];
const PACKAGE_MANAGER_COMMAND: Record<PackageManager, string> = {
  npm: "npm",
  yarn: "yarn",
  pnpm: "pnpm",
  bun: "bun",
};
const RUN_COMMAND: Record<PackageManager, string> = {
  npm: "npm run",
  yarn: "yarn run",
  pnpm: "pnpm run",
  bun: "bun run",
};
type PackageJsonInfo = {
  packageManager: PackageManager | null;
};
const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);
const parsePackageManagerField = (value: unknown): PackageManager | null => {
  if (typeof value !== "string") return null;
  const [name] = value.split("@");
  if (name === "npm" || name === "pnpm" || name === "bun") {
    return name;
  }
  if (name === "yarn" || name === "yarnpkg") {
    return "yarn";
  }
  return null;
};
const readPackageJson = async (
  packageJsonPath: string,
): Promise<PackageJsonInfo | null> => {
  if (!await fileExists(packageJsonPath)) {
    return null;
  }
  try {
    const raw = await Deno.readTextFile(packageJsonPath);
    const parsed = JSON.parse(raw) as unknown;
    if (!isRecord(parsed)) {
      return { packageManager: null };
    }
    return {
      packageManager: parsePackageManagerField(parsed.packageManager),
    };
  } catch (_error) {
    return null;
  }
};
const detectManagerByLockFile = async (
  directory: string,
): Promise<PackageManager | null> => {
  for (const { manager, files } of LOCKFILE_HINTS) {
    for (const file of files) {
      if (await fileExists(join(directory, file))) {
        return manager;
      }
    }
  }
  return null;
};
const collectSearchDirectories = (
  currentDirectory: string,
  projectRoot: string,
): string[] => {
  const resolvedCurrent = resolve(currentDirectory);
  const resolvedRoot = resolve(projectRoot);
  const directories: string[] = [];
  const seen = new Set<string>();
  let cursor = resolvedCurrent;
  while (true) {
    if (!seen.has(cursor)) {
      directories.push(cursor);
      seen.add(cursor);
    }
    if (cursor === resolvedRoot) break;
    const parent = dirname(cursor);
    if (parent === cursor) break;
    cursor = parent;
  }
  if (!seen.has(resolvedRoot)) {
    directories.push(resolvedRoot);
  }
  return directories;
};
type ProjectInfo = {
  packageManager: PackageManager;
  packageJsonPath: string;
};
const findProjectInfo = async (
  projectRoot: string,
  currentDirectory: string,
): Promise<ProjectInfo | null> => {
  for (
    const directory of collectSearchDirectories(currentDirectory, projectRoot)
  ) {
    const packageJsonPath = join(directory, "package.json");
    const packageJson = await readPackageJson(packageJsonPath);
    if (packageJson == null) {
      continue;
    }
    const lockFileManager = await detectManagerByLockFile(directory);
    const packageManager = lockFileManager ?? packageJson.packageManager ??
      "npm";
    return {
      packageManager,
      packageJsonPath,
    };
  }
  return null;
};
const escapeRegExp = (input: string): string =>
  input.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const escapeSingleQuotes = (value: string): string =>
  value.replaceAll("'", "'\\''");
const createScriptSourceCommand = (packageJsonPath: string): string => {
  const quotedPath = `'${escapeSingleQuotes(packageJsonPath)}'`;
  return `jq -r '(.scripts // {}) | to_entries[] | "\\(.key)\\t\\(.value)"' ${quotedPath}`;
};
export default defineConfig(async ({ projectRoot, currentDirectory }) => {
  const project = await findProjectInfo(projectRoot, currentDirectory);
  if (project == null) {
    return { snippets: [], completions: [] };
  }
  const { packageManager, packageJsonPath } = project;
  const packageCommand = PACKAGE_MANAGER_COMMAND[packageManager];
  const runCommand = RUN_COMMAND[packageManager];
  const completionPatterns = [
    `^${escapeRegExp(runCommand)} `,
    "^ni run ",
  ];
  const completions = [{
    name: `${runCommand} scripts`,
    patterns: Array.from(new Set(completionPatterns)),
    sourceCommand: createScriptSourceCommand(packageJsonPath),
    options: {
      "--prompt": `'${runCommand}> '`,
      "--delimiter": "'\\t'",
      "--with-nth": "1",
      "--preview": "printf '%s\\n' {2}",
      "--preview-window": "'down'",
    },
    callback: "awk -F '\\t' '{print $1}'",
  }];
  return {
    snippets: [
      {
        name: "n → package manager",
        keyword: "n",
        snippet: `${packageCommand}`,
      },
      {
        name: "nr → package manager run",
        keyword: "nr",
        snippet: `${runCommand}`,
      },
    ],
    completions,
  };
});
