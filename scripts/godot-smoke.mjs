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
      for (const marker of ["SCRIPT ERROR", "Parse Error", "ERROR: Failed to load"]) {
        if (output.includes(marker)) {
          reject(new Error(`Godot smoke test output contained "${marker}"\n${output}`));
          return;
        }
      }
      resolve(output);
    });
  });
}

await run("godot", ["--headless", "--path", "godot", "--quit-after", "1"]);
console.log("ok - Godot headless smoke passed");
