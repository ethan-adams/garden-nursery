import { spawn } from "node:child_process";

function run(command, args, { scanMarkers = true } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: "pipe" });
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

const output = await run("godot", [
  "--headless",
  "--path",
  "godot",
  "-s",
  "res://tests/run_tests.gd"
]);
process.stdout.write(output.trim() + "\n");
console.log("ok - Godot GDScript tests passed");
