import { readdir, readFile } from "node:fs/promises";
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

async function commandExists(command) {
  try {
    await run(command, ["--version"]);
    return true;
  } catch {
    return false;
  }
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

async function readJson(path) {
  return JSON.parse(await readFile(path, "utf8"));
}

check("JavaScript parses", async () => {
  await run("node", ["--check", "browser-prototype/game.js"]);
});

check("Browser entrypoint is wired", async () => {
  const html = await readFile("browser-prototype/index.html", "utf8");
  assert(html.includes('<link rel="stylesheet" href="styles.css">'), "index.html must load styles.css");
  assert(html.includes('<script src="game.js"></script>'), "index.html must load game.js");
  assert(html.includes('id="inventory"'), "index.html must include inventory mount");
  assert(html.includes('id="customers"'), "index.html must include customer mount");
});

check("Local visual assets are present", async () => {
  const css = await readFile("browser-prototype/styles.css", "utf8");
  const assetMatch = css.match(/url\("([^"]+)"\)/);
  assert(assetMatch, "styles.css should reference a background asset");
  assert(!assetMatch[1].startsWith("http"), "background asset should be local, not remote");
  assert(await fileExists(join("browser-prototype", assetMatch[1])), `missing referenced asset: ${assetMatch[1]}`);
});

check("Game has the core prototype loop", async () => {
  const js = await readFile("browser-prototype/game.js", "utf8");
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
  assert(mainScene.includes("[gd_scene") && mainScene.includes("format=3"), "main scene must be a Godot 4 text scene");
  assert(mainScene.includes('[node name="Main" type="Control"]'), "main scene must have a Control root named Main");

  const extResources = [...mainScene.matchAll(/\[ext_resource[^\]]+path="([^"]+)"/g)];
  for (const [, resourcePath] of extResources) {
    const repoPath = resourcePath.startsWith("res://")
      ? godotPathToRepoPath(resourcePath)
      : join(dirname(mainScenePath), resourcePath);
    assert(await fileExists(repoPath), `missing Godot scene resource: ${repoPath}`);
  }
});

check("Godot export preset is present", async () => {
  const presets = await readFile("godot/export_presets.cfg", "utf8");
  assert(presets.includes('name="Steam Deck"'), "export presets must include Steam Deck preset");
  assert(presets.includes('platform="Linux/X11"'), "Steam Deck preset must export Linux/X11");
  assert(presets.includes('export_path="../dist/steamdeck/GardenNursery.x86_64"'), "Steam Deck export path must target dist/steamdeck");
});

check("Core data catalogs are valid", async () => {
  const plantCatalog = await readJson("godot/data/plants/starter_plants.json");
  const customerCatalog = await readJson("godot/data/customers/hush_arbor_archetypes.json");
  const region = await readJson("godot/data/regions/hush_arbor.json");

  assert(plantCatalog.format === "garden-nursery.plants.v1", "plant catalog format must be v1");
  assert(Array.isArray(plantCatalog.plants), "plant catalog must include plants array");
  assert(plantCatalog.plants.length >= 3, "plant catalog must include at least 3 plants");
  for (const plant of plantCatalog.plants) {
    for (const required of ["id", "name", "category", "price", "starting_stock", "traits", "climate_fit", "care_needs", "market_notes"]) {
      assert(Object.hasOwn(plant, required), `plant ${plant.id ?? "(missing id)"} missing ${required}`);
    }
    assert(Array.isArray(plant.traits) && plant.traits.length >= 2, `plant ${plant.id} must define traits`);
    assert(Object.hasOwn(plant.care_needs, "water"), `plant ${plant.id} must define water care`);
    assert(Object.hasOwn(plant.care_needs, "light"), `plant ${plant.id} must define light care`);
  }

  assert(customerCatalog.format === "garden-nursery.customers.v1", "customer catalog format must be v1");
  assert(Array.isArray(customerCatalog.customers), "customer catalog must include customers array");
  assert(customerCatalog.customers.length >= 2, "customer catalog must include at least 2 customers");
  for (const customer of customerCatalog.customers) {
    for (const required of ["id", "display_name", "role", "budget", "garden_constraints", "taste", "contradiction", "market_hint"]) {
      assert(Object.hasOwn(customer, required), `customer ${customer.id ?? "(missing id)"} missing ${required}`);
    }
  }

  assert(region.format === "garden-nursery.region.v1", "region catalog format must be v1");
  assert(Array.isArray(region.market_signals) && region.market_signals.length >= 3, "region must define at least 3 market signals");
  assert(Array.isArray(region.week_outcomes) && region.week_outcomes.length >= 3, "region must define week outcomes");
  for (const signal of region.market_signals) {
    for (const required of ["id", "source", "text", "points_to_traits", "risk_traits", "uncertainty"]) {
      assert(Object.hasOwn(signal, required), `signal ${signal.id ?? "(missing id)"} missing ${required}`);
    }
  }
});

check("Writing sample pack is complete", async () => {
  const writing = await readJson("godot/data/dialogue/writing_sample_pack.json");
  const doc = await readFile("docs/writing-sample-pack.md", "utf8");

  assert(writing.format === "garden-nursery.dialogue.v1", "writing sample pack format must be v1");
  assert(Array.isArray(writing.characters) && writing.characters.length >= 3, "writing pack must include 3 character sketches");
  assert(Array.isArray(writing.customer_barks) && writing.customer_barks.length >= 10, "writing pack must include 10 barks");
  assert(Array.isArray(writing.week_reflections) && writing.week_reflections.length >= 3, "writing pack must include 3 week reflections");
  assert(Object.hasOwn(writing, "seasonal_event"), "writing pack must include seasonal event");
  for (const required of ["Mara Lye", "Tovan Ree", "Cilla Park", "First Seed Swap"]) {
    assert(doc.includes(required), `writing doc missing ${required}`);
  }
});

check("Nursery stand scene is playable shape", async () => {
  const scene = await readFile("godot/scenes/nursery/nursery_stand.tscn", "utf8");
  const script = await readFile("godot/scripts/ui/nursery_stand.gd", "utf8");
  for (const required of [
    "Market Signal Board",
    "Inventory Recommendations",
    "Regulars Today",
    "Week Outcome",
    "NextSignalButton",
    "AdvanceWeekButton",
    "focus_mode = 2"
  ]) {
    assert(scene.includes(required), `nursery stand scene missing ${required}`);
  }
  for (const required of [
    "PLANTS_PATH",
    "CUSTOMERS_PATH",
    "REGION_PATH",
    "_recommend_plant",
    "_on_advance_week_button_pressed",
    "_trait_score"
  ]) {
    assert(script.includes(required), `nursery stand script missing ${required}`);
  }
});

check("Optional Godot headless import passes", async () => {
  if (process.env.GARDEN_NURSERY_CHECK_GODOT !== "1") {
    return;
  }
  assert(await commandExists("godot"), "GARDEN_NURSERY_CHECK_GODOT=1 requires godot on PATH");
  const result = await run("godot", ["--headless", "--path", "godot", "--quit-after", "1"]);
  const output = `${result.stdout}\n${result.stderr}`;
  assert(!output.includes("SCRIPT ERROR"), "Godot reported a script error during headless import");
  assert(!output.includes("Parse Error"), "Godot reported a parse error during headless import");
  assert(!output.includes("ERROR: Failed to load"), "Godot failed to load a resource during headless import");
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

check("Starter region brief is documented", async () => {
  const doc = await readFile("docs/starter-region-brief.md", "utf8");
  for (const required of [
    "Hush Arbor",
    "Climate And Growing Conditions",
    "Ecology",
    "Seasonal Feel",
    "Cultural And Local-Market Hooks",
    "Magical-Realism Hooks",
    "Gentle Market-Reading Tutorial",
    "Early Vertical-Slice Signals"
  ]) {
    assert(doc.includes(required), `starter region brief missing ${required}`);
  }
});

check("Godot data directories contain editable catalogs", async () => {
  for (const directory of [
    "godot/data/plants",
    "godot/data/customers",
    "godot/data/regions",
    "godot/data/dialogue"
  ]) {
    const files = await readdir(directory);
    assert(files.some((file) => file.endsWith(".json")), `${directory} must include JSON catalog data`);
  }
});

check("Testing and build docs are present", async () => {
  const doc = await readFile("docs/testing-and-builds.md", "utf8");
  for (const required of [
    "npm test",
    "npm run test:product",
    "npm run export:steamdeck",
    "Steam Deck Test Path",
    "GitHub Actions"
  ]) {
    assert(doc.includes(required), `testing docs missing ${required}`);
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
