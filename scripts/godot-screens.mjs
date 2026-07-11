import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// Capture ship-evidence screenshots of the real game at 1280x800 (issue #98, Tier 2).
//
// Screenshots need a GL context, so this does NOT use --headless. On Linux (CI) it runs
// under `xvfb-run` for a virtual framebuffer; on macOS/desktop it renders to a window.
// Output lands in dist/screens/ (gitignored), which CI uploads as an artifact and the
// harness reads back to judge layout.

const OUT_DIR = resolve(process.cwd(), "dist/screens");

// The capture drives the real overlay, which autosaves to the same user:// path as a
// local playtest. Redirect Godot's user data dir into a throwaway home so capturing
// screenshots can never clobber Ethan's real save (screenshots land in OUT_DIR, an
// absolute path, so they are unaffected).
const CAPTURE_HOME = mkdtempSync(join(tmpdir(), "gn-godot-home-"));
const ISOLATED_ENV = {
  ...process.env,
  HOME: CAPTURE_HOME,
  XDG_DATA_HOME: join(CAPTURE_HOME, ".local", "share"),
};

function run(command, args, { scanMarkers = true } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: "pipe", env: ISOLATED_ENV });
    let out = "";
    child.stdout.on("data", (c) => (out += c));
    child.stderr.on("data", (c) => (out += c));
    child.on("error", reject);
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`${command} ${args.join(" ")} exited ${code}\n${out}`));
        return;
      }
      if (scanMarkers) {
        for (const marker of ["SCRIPT ERROR", "Parse Error", "ERROR: Failed to load", "capture: failed"]) {
          if (out.includes(marker)) {
            reject(new Error(`Screenshot capture output contained "${marker}"\n${out}`));
            return;
          }
        }
      }
      resolve(out);
    });
  });
}

// On Linux without a display, wrap Godot in xvfb-run so it gets a virtual framebuffer.
function godotInvocation(godotArgs) {
  if (process.platform === "linux" && !process.env.DISPLAY) {
    return ["xvfb-run", ["-a", "godot", ...godotArgs]];
  }
  return ["godot", godotArgs];
}

rmSync(OUT_DIR, { recursive: true, force: true });
mkdirSync(OUT_DIR, { recursive: true });

// A fresh checkout has the committed .import sidecars but not the generated .ctex data
// the scenes render, so force a full import first (headless is fine — no rendering yet).
await run("godot", ["--headless", "--path", "godot", "--import"], { scanMarkers: false });

const [cmd, baseArgs] = godotInvocation([
  "--rendering-driver",
  "opengl3",
  "--path",
  "godot",
  "-s",
  "res://tools/capture_screens.gd",
  "--",
  OUT_DIR,
]);
try {
  const output = await run(cmd, baseArgs);
  process.stdout.write(output.trim() + "\n");
  console.log(`ok - screenshots captured to ${OUT_DIR}`);
} finally {
  rmSync(CAPTURE_HOME, { recursive: true, force: true });
}
