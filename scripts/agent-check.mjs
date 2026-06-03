import { readFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { access } from "node:fs/promises";
import { dirname, join } from "node:path";

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

function godotPathToRepoPath(path) {
  assert(path.startsWith("res://"), `Godot path must use res://: ${path}`);
  return join("godot", path.slice("res://".length));
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

check("Godot project shell is wired", async () => {
  const projectPath = "godot/project.godot";
  const project = await readFile(projectPath, "utf8");

  assert(project.includes("config_version=5"), "project.godot must use Godot 4 config_version=5");
  assert(project.includes('config/features=PackedStringArray("4.5")'), "project.godot must target Godot 4.5");
  assert(project.includes("window/size/viewport_width=1280"), "project.godot must target 1280 viewport width");
  assert(project.includes("window/size/viewport_height=800"), "project.godot must target 800 viewport height");
  assert(project.includes('window/stretch/mode="canvas_items"'), "project.godot must use canvas_items stretch mode");
  assert(project.includes('window/stretch/aspect="expand"'), "project.godot must use expand stretch aspect");

  const mainSceneMatch = project.match(/run\/main_scene="([^"]+)"/);
  assert(mainSceneMatch, "project.godot must define application run/main_scene");
  const mainScenePath = godotPathToRepoPath(mainSceneMatch[1]);
  assert(await fileExists(mainScenePath), `missing Godot main scene: ${mainScenePath}`);

  const iconMatch = project.match(/config\/icon="([^"]+)"/);
  assert(iconMatch, "project.godot must define application config/icon");
  const iconPath = godotPathToRepoPath(iconMatch[1]);
  assert(await fileExists(iconPath), `missing Godot project icon: ${iconPath}`);

  const mainScene = await readFile(mainScenePath, "utf8");
  assert(mainScene.includes("[gd_scene format=3"), "main scene must be a Godot 4 text scene");
  assert(mainScene.includes('[node name="Main" type="Control"]'), "main scene must have a Control root named Main");

  const extResources = [...mainScene.matchAll(/\[ext_resource[^\]]+path="([^"]+)"/g)];
  for (const [, resourcePath] of extResources) {
    const repoPath = resourcePath.startsWith("res://")
      ? godotPathToRepoPath(resourcePath)
      : join(dirname(mainScenePath), resourcePath);
    assert(await fileExists(repoPath), `missing Godot scene resource: ${repoPath}`);
  }
});

check("Steam Deck UX baseline is documented", async () => {
  const doc = await readFile("docs/steam-deck-ux-baseline.md", "utf8");
  for (const required of [
    "1280x800",
    "Text Sizing",
    "Focus Navigation",
    "Input Actions",
    "Current Automated Checks",
    "Manual Checks Later",
    "ui_confirm",
    "ui_cancel",
    "ui_details",
    "ui_tab_next",
    "ui_tab_previous"
  ]) {
    assert(doc.includes(required), `Steam Deck UX baseline missing ${required}`);
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
