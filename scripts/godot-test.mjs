import { spawn } from "node:child_process";

function run(command, args) {
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
      for (const marker of ["SCRIPT ERROR", "Parse Error", "ERROR: Failed to load", "FAIL -"]) {
        if (output.includes(marker)) {
          reject(new Error(`Godot test output contained "${marker}"\n${output}`));
          return;
        }
      }
      resolve(output);
    });
  });
}

const output = await run("godot", [
  "--headless",
  "--path",
  "godot",
  "-s",
  "res://tests/run_tests.gd"
]);
process.stdout.write(output.trim() + "\n");
console.log("ok - Godot GDScript tests passed");
