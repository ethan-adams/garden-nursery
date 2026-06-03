import { mkdir } from "node:fs/promises";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const GODOT_TEMPLATE_VERSION = "4.5.1.stable";

const targets = {
  steamdeck: {
    preset: "Steam Deck",
    outputDir: join("dist", "steamdeck"),
    outputPathFromGodotProject: "../dist/steamdeck/GardenNursery.x86_64",
    requiredTemplates: ["linux_debug.x86_64", "linux_release.x86_64"]
  }
};

const targetName = process.argv[2] ?? "steamdeck";
const target = targets[targetName];

if (!target) {
  console.error(`Unknown export target "${targetName}". Known targets: ${Object.keys(targets).join(", ")}`);
  process.exit(1);
}

function templateRoot() {
  if (process.env.GODOT_EXPORT_TEMPLATES_DIR) {
    return process.env.GODOT_EXPORT_TEMPLATES_DIR;
  }
  if (process.platform === "darwin") {
    return join(homedir(), "Library", "Application Support", "Godot", "export_templates", GODOT_TEMPLATE_VERSION);
  }
  if (process.platform === "win32") {
    return join(process.env.APPDATA ?? join(homedir(), "AppData", "Roaming"), "Godot", "export_templates", GODOT_TEMPLATE_VERSION);
  }
  return join(homedir(), ".local", "share", "godot", "export_templates", GODOT_TEMPLATE_VERSION);
}

function assertTemplatesInstalled() {
  const root = templateRoot();
  const missing = target.requiredTemplates
    .map((template) => join(root, template))
    .filter((path) => !existsSync(path));

  if (missing.length === 0) {
    return;
  }

  console.error(`Missing Godot ${GODOT_TEMPLATE_VERSION} export templates for ${target.preset}.`);
  console.error("Expected:");
  for (const path of missing) {
    console.error(`- ${path}`);
  }
  console.error("");
  console.error("Install export templates in the Godot editor, or set GODOT_EXPORT_TEMPLATES_DIR to the directory containing linux_debug.x86_64 and linux_release.x86_64.");
  console.error("CI installs these templates automatically.");
  process.exit(1);
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: "pipe" });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
      process.stdout.write(chunk);
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
      process.stderr.write(chunk);
    });
    child.on("close", (code) => {
      const output = `${stdout}\n${stderr}`;
      if (code !== 0) {
        reject(new Error(`Godot export exited ${code}`));
        return;
      }
      for (const marker of ["SCRIPT ERROR", "Parse Error", "ERROR: Failed to load"]) {
        if (output.includes(marker)) {
          reject(new Error(`Godot export output contained "${marker}"`));
          return;
        }
      }
      resolve();
    });
  });
}

assertTemplatesInstalled();
await mkdir(target.outputDir, { recursive: true });
await run("godot", ["--headless", "--path", "godot", "--export-debug", target.preset, target.outputPathFromGodotProject]);
console.log(`ok - exported ${target.preset} to ${target.outputDir}`);
