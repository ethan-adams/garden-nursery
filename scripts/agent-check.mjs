import { readFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { access } from "node:fs/promises";

const checks = [];

function check(name, fn) {
  checks.push({ name, fn });
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "pipe"
    });

    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("close", (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`${command} ${args.join(" ")} failed\n${stdout}${stderr}`));
      }
    });
  });
}

async function fileExists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

check("JavaScript parses", async () => {
  await run("node", ["--check", "game.js"]);
});

check("Browser entrypoint is wired", async () => {
  const html = await readFile("index.html", "utf8");
  assert(html.includes('<link rel="stylesheet" href="styles.css">'), "index.html must load styles.css");
  assert(html.includes('<script src="game.js"></script>'), "index.html must load game.js");
  assert(html.includes('id="inventory"'), "index.html must include inventory mount");
  assert(html.includes('id="customers"'), "index.html must include customer mount");
});

check("Local visual assets are present", async () => {
  const css = await readFile("styles.css", "utf8");
  const assetMatch = css.match(/url\("([^"]+)"\)/);
  assert(assetMatch, "styles.css should reference a background asset");
  assert(!assetMatch[1].startsWith("http"), "background asset should be local, not remote");
  assert(await fileExists(assetMatch[1]), `missing referenced asset: ${assetMatch[1]}`);
});

check("Game has the core prototype loop", async () => {
  const js = await readFile("game.js", "utf8");
  for (const required of ["sellPlant", "restockFavorites", "hybridize", "nextWeek", "generateCustomers"]) {
    assert(js.includes(`function ${required}`), `game.js missing ${required}()`);
  }
});

let failed = false;
for (const item of checks) {
  try {
    await item.fn();
    console.log(`ok - ${item.name}`);
  } catch (error) {
    failed = true;
    console.error(`not ok - ${item.name}`);
    console.error(error.message);
  }
}

if (failed) {
  process.exitCode = 1;
}
