import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// The scene tests drive the real overlay, which loads and autosaves to
// user://garden_nursery_vertical_slice_save.json — the same path a local playtest uses.
// Redirect Godot's user data dir into a throwaway home so the pre-commit gate can never
// touch Ethan's real save (HOME covers macOS ~/Library, XDG_DATA_HOME covers Linux).
const TEST_HOME = mkdtempSync(join(tmpdir(), "gn-godot-home-"));
const ISOLATED_ENV = {
  ...process.env,
  HOME: TEST_HOME,
  XDG_DATA_HOME: join(TEST_HOME, ".local", "share"),
};

function run(command, args, { scanMarkers = true } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: "pipe", env: ISOLATED_ENV });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("close", (code) => {
      const output = `${stdout}\n${stderr}`;
      if (code !== 0) {
        reject(new Error(`${command} ${args.join(" ")} exited ${code}\n${output}`));
        return;
      }
      if (scanMarkers) {
        for (const marker of ["SCRIPT ERROR", "Parse Error", "ERROR: Failed to load", "FAIL -"]) {
          if (output.includes(marker)) {
            reject(new Error(`Godot test output contained "${marker}"\n${output}`));
            return;
          }
        }
      }
      resolve(output);
    });
  });
}

// Imported textures live in the gitignored .godot/imported cache, not in git, so a
// fresh checkout (CI, a clean clone) has the committed .import sidecars but not the
// generated .ctex data the scenes load. Force a full import first so the test runner
// is self-sufficient anywhere; only a hard failure (non-zero exit) aborts here, since
// import logs are noisy and not the thing under test.
await run("godot", ["--headless", "--path", "godot", "--import"], { scanMarkers: false });

try {
  const output = await run("godot", [
    "--headless",
    "--path",
    "godot",
    "-s",
    "res://tests/run_tests.gd"
  ]);
  process.stdout.write(output.trim() + "\n");
  console.log("ok - Godot GDScript tests passed");
} finally {
  rmSync(TEST_HOME, { recursive: true, force: true });
}
