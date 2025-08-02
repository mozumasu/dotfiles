#!/usr/bin/env -S deno run --allow-read
import { dirname } from "https://deno.land/std/path/mod.ts";

const detectPackageManager = async (cwd: string) => {
  const packageManagers = [
    { name: "npm", lockFile: "package-lock.json" },
    { name: "yarn", lockFile: "yarn.lock" },
    { name: "pnpm", lockFile: "pnpm-lock.yaml" },
  ];

  for (let dir = cwd; ;) {
    for (const { name, lockFile } of packageManagers) {
      try {
        const info = await Deno.lstat(`${dir}/${lockFile}`);
        if (info.isFile) {
          return name;
        }
      } catch (_err) {
        // ignore
      }
    }

    const parent = dirname(dir);
    if (parent === dir) {
      break;
    }
    dir = parent;
  }

  return "npm";
};

console.log(await detectPackageManager(Deno.cwd()));
