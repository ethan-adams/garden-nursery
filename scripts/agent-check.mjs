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
  await run("node", ["--check", "scripts/simulation-rules.mjs"]);
  await run("node", ["--check", "scripts/simulation-rules.test.mjs"]);
});

check("Simulation rule tests are wired into npm test", async () => {
  const pkg = await readJson("package.json");
  assert(pkg.scripts["test:rules"] === "node scripts/simulation-rules.test.mjs", "package.json must define test:rules");
  assert(pkg.scripts.test.includes("npm run test:rules"), "npm test must run simulation rule tests");
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

check("Godot walkable yard station scene is wired", async () => {
  const project = await readFile("godot/project.godot", "utf8");
  const mainScene = await readFile("godot/scenes/main/main.tscn", "utf8");
  const yardScene = await readFile("godot/scenes/nursery/nursery_yard.tscn", "utf8");
  const playerScene = await readFile("godot/scenes/player/player.tscn", "utf8");
  const yardScript = await readFile("godot/scripts/world/nursery_yard.gd", "utf8");
  const stationScript = await readFile("godot/scripts/world/station_interactable.gd", "utf8");
  const playerScript = await readFile("godot/scripts/player/player_controller.gd", "utf8");
  const standScript = await readFile("godot/scripts/ui/nursery_stand.gd", "utf8");
  const rulesScript = await readFile("godot/scripts/core/nursery_rules.gd", "utf8");

  assert(mainScene.includes('path="res://scenes/nursery/nursery_yard.tscn"'), "main scene must instance the walkable nursery yard");
  assert(yardScene.includes('path="res://scripts/world/nursery_yard.gd"'), "nursery yard must use the yard interaction controller");
  assert(yardScene.includes('path="res://scripts/world/station_interactable.gd"'), "nursery yard must load the reusable station interactable script");
  assert(yardScene.includes('path="res://scenes/nursery/nursery_stand.tscn"'), "nursery yard must include the station overlay scene");
  assert(yardScene.includes('node name="Player"'), "nursery yard must include the player");
  assert(playerScene.includes('node name="Camera2D"'), "player scene must include a Camera2D");
  assert(yardScene.includes('node name="StationPrompt"'), "nursery yard must include an interaction prompt");
  assert(yardScene.includes('node name="StationOverlay"'), "nursery yard must include a station overlay layer");
  assert(yardScene.includes('node name="StationReadabilityMarkers"'), "nursery yard must include station readability markers");

  for (const [nodeName, stationId] of [
    ["SignalBoardStation", "signal_board"],
    ["PlantStandStation", "plant_stand"],
    ["PropagationBenchStation", "propagation_bench"],
    ["LedgerStation", "ledger"],
    ["JournalStation", "journal"]
  ]) {
    assert(yardScene.includes(`node name="${nodeName}" type="Area2D"`), `nursery yard missing ${nodeName}`);
    assert(yardScene.includes(`station_id = "${stationId}"`), `${nodeName} must define station_id ${stationId}`);
  }

  // Station names are painted onto diegetic sign planks in the yard art; the scene
  // layers a SignLabel-themed Label over each plank so the text stays crisp and
  // editable. Guard the sign layer so stations never lose their at-a-glance names.
  for (const [markerName, stationLabel] of [
    ["SignalMarker", "Signal Board"],
    ["PlantStandMarker", "Plant Stand"],
    ["PropagationMarker", "Trays"],
    ["LedgerMarker", "Ledger"],
    ["JournalMarker", "Journal"]
  ]) {
    assert(yardScene.includes(`node name="${markerName}"`), `nursery yard missing ${markerName}`);
    assert(yardScene.includes(`text = "${stationLabel}"`), `${markerName} must include readable ${stationLabel} sign label`);
  }
  const signLabelCount = (yardScene.match(/theme_type_variation = &"SignLabel"/g) ?? []).length;
  assert(signLabelCount >= 5, "every station sign label must use the SignLabel theme variation");

  for (const required of [
    "station_activated",
    "ONBOARDING_FLOW",
    "_current_onboarding_step",
    "_station_direction_text",
    "open_station",
    "get_prompt_text",
    "ui_confirm",
    "set_movement_enabled(false)",
    "set_movement_enabled(true)"
  ]) {
    assert(yardScript.includes(required), `nursery yard controller missing ${required}`);
  }

  for (const required of ["station_id", "station_name", "action_label", "get_prompt_position"]) {
    assert(stationScript.includes(required), `station interactable script missing ${required}`);
  }

  for (const required of ["move_speed := 178.0", "deceleration", "play_bounds", "Input.get_vector"]) {
    assert(playerScript.includes(required), `player controller missing ${required}`);
  }

  for (const required of ["signal closed", "func open_station", "station_mode", "ui_cancel"]) {
    assert(standScript.includes(required), `nursery stand overlay missing ${required}`);
  }

  for (const required of [
    "class_name NurseryRules",
    "score_customer_fit",
    "care_climate_fit",
    "customer_recommendation_outcome",
    "best_outcome_for",
    "trait_score"
  ]) {
    assert(rulesScript.includes(required), `nursery rules script missing ${required}`);
  }

  for (const action of ["ui_confirm", "ui_cancel", "ui_tab_next", "ui_tab_previous"]) {
    assert(project.includes(`${action}={`), `project.godot missing input action ${action}`);
  }
});

check("Godot export preset is present", async () => {
  const presets = await readFile("godot/export_presets.cfg", "utf8");
  assert(presets.includes('name="Steam Deck"'), "export presets must include Steam Deck preset");
  assert(presets.includes('platform="Linux/X11"'), "Steam Deck preset must export Linux/X11");
  assert(presets.includes('export_path="../dist/steamdeck/GardenNursery.x86_64"'), "Steam Deck export path must target dist/steamdeck");

  // The export must run a --import pass before --export-debug. The project loads its
  // custom gui theme (referencing imported fonts) at engine boot, before a single-pass
  // export's own filesystem scan imports it, so a fresh checkout aborts without this.
  const exportScript = await readFile("scripts/export-godot.mjs", "utf8");
  assert(exportScript.includes('"--import"'), "export-godot.mjs must import the project before exporting so imported data exists on a fresh checkout");
});

check("Art loads through the import pipeline, not runtime file reads", async () => {
  // Image.load_from_file / FileAccess-style asset reads work from the editor but
  // silently fail in an exported PCK, leaving a gray void (issue #92). Scene art must
  // reference committed imported textures instead. Guard against a regression to
  // runtime asset loading in gameplay scripts.
  async function collectScripts(dir) {
    const found = [];
    for (const entry of await readdir(dir, { withFileTypes: true })) {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) {
        found.push(...(await collectScripts(path)));
      } else if (entry.name.endsWith(".gd")) {
        found.push(path);
      }
    }
    return found;
  }

  for (const path of await collectScripts("godot/scripts")) {
    const source = await readFile(path, "utf8");
    assert(
      !source.includes("Image.load_from_file"),
      `${path} loads art at runtime with Image.load_from_file; reference an imported texture in the scene instead`
    );
  }

  // The imported textures the scenes depend on must be committed (their .import
  // sidecars are what the exporter uses to pack the .ctex into the build).
  for (const asset of ["hush-arbor-yard.png", "gardener-player.png"]) {
    assert(
      await fileExists(`godot/assets/art/${asset}.import`),
      `godot/assets/art/${asset}.import must be committed so the texture ships in the export`
    );
  }

  // The committed PNGs are rasterized from editable SVG sources by rasterize_art.gd; the
  // SVGs are the art's source of truth (issue: craft-pass). Guard the tool the same way
  // capture_screens.gd is guarded, so a refactor can't silently delete the regeneration
  // path and leave the PNGs orphaned from their sources.
  const rasterizer = await readFile("godot/tools/rasterize_art.gd", "utf8");
  assert(rasterizer.includes("save_png"), "rasterize_art.gd must save the PNGs it rasterizes from SVG");
  for (const svg of ["hush-arbor-yard.svg", "gardener-player.svg"]) {
    assert(await fileExists(`godot/assets/art/${svg}`), `missing SVG art source: godot/assets/art/${svg}`);
    assert(rasterizer.includes(svg), `rasterize_art.gd must regenerate ${svg}`);
  }

  const yardScene = await readFile("godot/scenes/nursery/nursery_yard.tscn", "utf8");
  const playerScene = await readFile("godot/scenes/player/player.tscn", "utf8");
  assert(
    yardScene.includes('type="Texture2D" path="res://assets/art/hush-arbor-yard.png"'),
    "nursery_yard.tscn must reference the yard texture as an imported resource"
  );
  assert(
    playerScene.includes('type="Texture2D" path="res://assets/art/gardener-player.png"'),
    "player.tscn must reference the player texture as an imported resource"
  );
});

check("Nursery UI theme is wired with licensed fonts", async () => {
  // The workbench theme (art bible: paper/wood/slate surfaces, opaque panels, marigold
  // controller focus) must stay the project-wide gui theme, and its fonts must ship
  // with their OFL license texts. Guard against a regression to default-theme chrome.
  const project = await readFile("godot/project.godot", "utf8");
  assert(
    project.includes('theme/custom="res://assets/ui/nursery_theme.tres"'),
    "project.godot must set the nursery workbench theme as the custom gui theme"
  );
  const theme = await readFile("godot/assets/ui/nursery_theme.tres", "utf8");
  for (const variation of ["SlatePanel", "KraftPanel", "WoodPanel", "SignLabel", "PrimaryButton"]) {
    assert(theme.includes(`${variation}/base_type`), `nursery theme missing ${variation} variation`);
  }
  assert(theme.includes("button_focus"), "nursery theme must style controller focus on buttons");
  for (const fontFile of [
    "godot/assets/fonts/AlegreyaSans-Regular.ttf",
    "godot/assets/fonts/AlegreyaSans-Bold.ttf",
    "godot/assets/fonts/Alegreya-Variable.ttf",
    "godot/assets/fonts/OFL-AlegreyaSans.txt",
    "godot/assets/fonts/OFL-Alegreya.txt"
  ]) {
    assert(await fileExists(fontFile), `missing committed font asset: ${fontFile}`);
  }
});

check("Station overlay fits 1280x800 with working controller focus", async () => {
  // The stand overlay must scroll long lists (issue #94) so no focusable element sits
  // offscreen at 1280x800, and scroll must follow focus. Guard the ScrollContainers and
  // the follow_focus flag against a regression to the old overflowing VBoxes.
  const stand = await readFile("godot/scenes/nursery/nursery_stand.tscn", "utf8");
  const standScript = await readFile("godot/scripts/ui/nursery_stand.gd", "utf8");
  const scrollCount = (stand.match(/type="ScrollContainer"/g) ?? []).length;
  assert(scrollCount >= 3, "the inventory, customer, and outcome lists must live in ScrollContainers");
  const followFocusCount = (stand.match(/follow_focus = true/g) ?? []).length;
  assert(followFocusCount >= scrollCount, "every overlay ScrollContainer must set follow_focus so focus stays visible");

  // The customer cards are rendered at runtime; follow_focus only scrolls to a focusable
  // child, so the render code must make each card focusable (a bare Label draws no focus
  // state). Guard the line that makes "Regulars Today" controller-walkable.
  assert(
    /card\.focus_mode = Control\.FOCUS_ALL/.test(standScript),
    "customer cards must be focusable so the controller can walk the regulars and scroll follows focus"
  );

  // Input actions must be honest: the shoulder-button focus jump is wired, and the old
  // orphan actions the playtest doc lied about are gone.
  const project = await readFile("godot/project.godot", "utf8");
  for (const action of ["ui_tab_next", "ui_tab_previous"]) {
    assert(project.includes(`${action}={`), `project.godot missing input action ${action}`);
    assert(standScript.includes(`"${action}"`), `nursery_stand.gd must handle ${action}`);
  }
  for (const dead of ["ui_details", "ui_sort", "ui_journal"]) {
    assert(!project.includes(`${dead}={`), `dead input action ${dead} must be removed or wired to real behavior`);
  }
});

check("Self-playtest harness drives the real game", async () => {
  // Issue #98: the game must verify itself so a human isn't the only playtester.
  // Tier 1 — the GDScript runner must mount the real overlay in the tree and assert
  // observable behavior (scroll-follows-focus, on-screen focus, the flow moving the run
  // forward), not just run pure-logic checks. Guard the driving machinery.
  const runner = await readFile("godot/tests/run_tests.gd", "utf8");
  assert(runner.includes("SCENE_TESTS"), "run_tests.gd must define scene-driven behavioral tests (issue #98)");
  assert(
    /scene_test_scroll_follows_focus_into_view/.test(runner),
    "the scroll-follows-focus behavioral test must survive"
  );
  assert(runner.includes("open_station"), "scene tests must mount and drive the real stand overlay in-tree");
  assert(/await\s+process_frame/.test(runner), "scene tests must await frames so layout settles before asserting");

  // Tier 2 — a screenshot capture tool renders the real game for ship evidence, wired
  // into an npm script and CI so it runs on every push.
  const capture = await readFile("godot/tools/capture_screens.gd", "utf8");
  assert(capture.includes("save_png"), "capture_screens.gd must save PNG screenshots of the real game");
  const pkg = JSON.parse(await readFile("package.json", "utf8"));
  assert(pkg.scripts?.["godot:screens"], "package.json must wire the godot:screens capture script");
  const ci = await readFile(".github/workflows/sanity.yml", "utf8");
  assert(ci.includes("npm run godot:screens"), "CI must run the screenshot capture and upload the artifact");
});

check("The week has a real action economy", async () => {
  // The week must stay a constraint (issue #93): scarce per-week actions, no infinite
  // restock-recommend loop, and reputation consumed by the visit budget. Guard the
  // machinery so a future refactor can't quietly delete it and reopen the exploit.
  const runState = await readFile("godot/scripts/core/nursery_run_state.gd", "utf8");
  for (const required of [
    "func week_action_budget",
    "func has_week_action",
    "func spend_week_action",
    "week_actions_remaining",
    "weekly_recommended_plant_ids"
  ]) {
    assert(runState.includes(required), `weekly action economy missing ${required}`);
  }
  // Reputation must feed the visit budget (consumed, not inert).
  assert(
    /reputation\s*\/\s*WEEK_ACTION_REPUTATION_STEP/.test(runState),
    "the weekly visit budget must scale with reputation so reputation is consumed"
  );
  // Each spendable action must actually spend a visit, and recommend must guard against
  // re-pitching the same plant in one week.
  const spendCount = (runState.match(/spend_week_action\(\)/g) ?? []).length;
  assert(spendCount >= 4, "recommend, restock, and propagation must each spend a week action (plus the definition)");
  assert(
    runState.includes("weekly_recommended_plant_ids.has(plant_id)"),
    "recommend_plant must refuse a second same-week pitch of the same plant"
  );
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
    assert(Object.hasOwn(plant, "propagation"), `plant ${plant.id} must define propagation`);
    for (const required of ["method", "weeks", "cost", "yield", "success_chance", "notes"]) {
      assert(Object.hasOwn(plant.propagation, required), `plant ${plant.id} propagation missing ${required}`);
    }
    assert(plant.propagation.weeks >= 1, `plant ${plant.id} propagation must take at least one week`);
    assert(plant.propagation.yield >= 1, `plant ${plant.id} propagation must yield at least one plant`);
    assert(plant.propagation.success_chance > 0 && plant.propagation.success_chance <= 1, `plant ${plant.id} propagation success chance must be 0-1`);
  }

  assert(customerCatalog.format === "garden-nursery.customers.v1", "customer catalog format must be v1");
  assert(Array.isArray(customerCatalog.customers), "customer catalog must include customers array");
  assert(customerCatalog.customers.length >= 2, "customer catalog must include at least 2 customers");
  for (const customer of customerCatalog.customers) {
    for (const required of ["id", "display_name", "role", "budget", "garden_constraints", "taste", "contradiction", "market_hint", "returning_beats"]) {
      assert(Object.hasOwn(customer, required), `customer ${customer.id ?? "(missing id)"} missing ${required}`);
    }
    for (const required of ["trust_up", "careful", "trust_down"]) {
      assert(Object.hasOwn(customer.returning_beats, required), `customer ${customer.id} returning_beats missing ${required}`);
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
  assert(Object.hasOwn(region, "climate_profile"), "region missing climate_profile");
  for (const required of ["water", "light", "soil", "frost", "heat", "forgiving_traits", "risk_traits"]) {
    assert(Object.hasOwn(region.climate_profile, required), `region climate_profile missing ${required}`);
  }
  assert(Array.isArray(region.season_calendar) && region.season_calendar.length >= 5, "region must define a season calendar");
  for (const entry of region.season_calendar) {
    for (const required of ["week", "season", "weather", "forecast", "points_to_traits", "risk_traits", "propagation_bonus_traits", "propagation_risk_traits", "uncertainty"]) {
      assert(Object.hasOwn(entry, required), `season calendar week ${entry.week ?? "(missing week)"} missing ${required}`);
    }
  }
  assert(Array.isArray(region.community_events) && region.community_events.length >= 1, "region must define community events");
  for (const event of region.community_events) {
    for (const required of ["id", "name", "start_week", "deadline_week", "request", "preferred_traits", "etiquette", "cash_reward", "reputation_reward", "relationship_note"]) {
      assert(Object.hasOwn(event, required), `community event ${event.id ?? "(missing id)"} missing ${required}`);
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
  const runStateScript = await readFile("godot/scripts/core/nursery_run_state.gd", "utf8");
  for (const required of [
    "Market Signal Board",
    "Inventory Recommendations",
    "Regulars Today",
    "Week Outcome",
    "Propagation Bench",
    "NextSignalButton",
    "StartPropagationButton",
    "AdvanceWeekButton",
    "RestockButton",
    "EventButton",
    "ResetRunButton",
    "focus_mode = 2"
  ]) {
    assert(scene.includes(required), `nursery stand scene missing ${required}`);
  }
  for (const required of [
    "PLANTS_PATH",
    "CUSTOMERS_PATH",
    "REGION_PATH",
    "NurseryRunState",
    "run_state",
    "_recommend_plant",
    "_on_start_propagation_button_pressed",
    "_on_restock_button_pressed",
    "_on_event_button_pressed",
    "_on_advance_week_button_pressed",
    "_load_saved_state",
    "_save_run_state",
    "_on_reset_run_button_pressed",
    "_render_journal",
    "_journal_plants_text",
    "SAVE_FORMAT"
  ]) {
    assert(script.includes(required), `nursery stand script missing ${required}`);
  }
  for (const required of [
    "class_name NurseryRunState",
    "func recommend_plant",
    "func start_propagation",
    "func process_propagation_week",
    "func active_propagation_count",
    "func has_open_propagation_slot",
    "func propagation_status_lines",
    "func plant_care_text",
    "func update_customer_memory",
    "func customer_memory_text",
    "customer_memory",
    "event_contributions",
    "resolved_events",
    "func active_community_event",
    "func contribute_selected_plant_to_event",
    "func resolve_due_community_events",
    "func restock_selected_plant",
    "func restock_quote",
    "func inventory_economy_text",
    "func current_calendar_entry",
    "func merged_signal_with_calendar",
    "func propagation_weather_adjustment",
    "func calendar_summary_text",
    "propagation_capacity := 3",
    "propagation_trays",
    "func advance_week",
    "func save_state_snapshot",
    "func apply_saved_state",
    "func remember_week_reflection"
  ]) {
    assert(runStateScript.includes(required), `nursery run state script missing ${required}`);
  }
});

check("Vertical slice save format is documented", async () => {
  const doc = await readFile("docs/vertical-slice-save-format.md", "utf8");
  const script = await readFile("godot/scripts/ui/nursery_stand.gd", "utf8");
  const runStateScript = await readFile("godot/scripts/core/nursery_run_state.gd", "utf8");
  for (const required of [
    "garden_nursery_vertical_slice_save.json",
    "garden-nursery.save.v1",
    "inventory_stock",
    "propagation_trays",
    "propagation_capacity",
    "customer_notes",
    "customer_memory",
    "event_contributions",
    "resolved_events",
    "week_reflections",
    "weekly_activity",
    "Reset Run"
  ]) {
    assert(doc.includes(required), `save format doc missing ${required}`);
  }
  for (const required of [
    "SAVE_PATH",
    "save_state_snapshot",
    "apply_saved_state",
    "FileAccess.WRITE"
  ]) {
    assert(script.includes(required), `save implementation missing ${required}`);
  }
  for (const required of [
    "propagation_trays",
    "propagation_capacity",
    "next_propagation_tray_id",
    "propagation_tray",
    "sanitize_propagation_trays",
    "legacy_propagation_tray_snapshot",
    "inventory_stock",
    "customer_notes",
    "customer_memory",
    "weekly_activity"
  ]) {
    assert(runStateScript.includes(required), `save state model missing ${required}`);
  }
});

check("Propagation bench supports multiple trays", async () => {
  const script = await readFile("godot/scripts/ui/nursery_stand.gd", "utf8");
  const runStateScript = await readFile("godot/scripts/core/nursery_run_state.gd", "utf8");
  for (const required of [
    "propagation_slots_label",
    "propagation_status_lines",
    "has_open_propagation_slot",
    "Start Tray (%d/%d)"
  ]) {
    assert(script.includes(required), `propagation bench UI missing ${required}`);
  }
  for (const required of [
    "propagation_capacity := 3",
    "active_propagation_count() >= propagation_capacity",
    "remaining_trays",
    "complete_propagation_tray",
    "partly rooted"
  ]) {
    assert(runStateScript.includes(required), `propagation queue model missing ${required}`);
  }
});

check("Inventory economy supports restocking", async () => {
  const scene = await readFile("godot/scenes/nursery/nursery_stand.tscn", "utf8");
  const script = await readFile("godot/scripts/ui/nursery_stand.gd", "utf8");
  const runStateScript = await readFile("godot/scripts/core/nursery_run_state.gd", "utf8");
  for (const required of ["RestockButton", "_on_restock_button_pressed", "Order %d for $%d"]) {
    assert(scene.includes(required) || script.includes(required), `restock UI missing ${required}`);
  }
  for (const required of ["restock_selected_plant", "restock_quote", "stock_limit_for", "restock_margin_text", "weekly_restock_spend", "inventory_economy_text"]) {
    assert(runStateScript.includes(required), `restock economy model missing ${required}`);
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

check("Visual development pipeline is documented", async () => {
  const bible = await readFile("docs/art-bible.md", "utf8");
  const pipeline = await readFile("docs/visual-development-pipeline.md", "utf8");
  const brief = await readFile("docs/art-asset-brief-template.md", "utf8");
  const stationBrief = await readFile("docs/visual-references/hush-arbor-station-readability-brief.md", "utf8");

  for (const required of [
    "Botanical Specificity",
    "Steam Deck Readability",
    "UI Rules",
    "Asset Bar",
    "Source And Rights Rule"
  ]) {
    assert(bible.includes(required), `art bible missing ${required}`);
  }

  for (const required of [
    "Research Takeaways",
    "Visual Brief",
    "Reference Board",
    "Godot Integration",
    "AI-Assisted Art Rules",
    "Agent Workflow"
  ]) {
    assert(pipeline.includes(required), `visual pipeline missing ${required}`);
  }

  for (const required of [
    "Gameplay Job",
    "Style Target",
    "Production Plan",
    "Acceptance Checks"
  ]) {
    assert(brief.includes(required), `art asset brief template missing ${required}`);
  }

  for (const required of [
    "Hush Arbor Station Readability Brief",
    "1280x800",
    "No third-party art",
    "Colored ground plaques",
    "Prompt text does not cover the main silhouette"
  ]) {
    assert(stationBrief.includes(required), `station readability brief missing ${required}`);
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

check("Vertical slice playtest build notes are documented", async () => {
  const doc = await readFile("docs/vertical-slice-0.1-playtest-build.md", "utf8");
  for (const required of [
    "garden-nursery-steamdeck-debug",
    "GardenNursery.x86_64",
    "Controls",
    "Known Limitations",
    "Feedback Needed",
    "save/load"
  ]) {
    assert(doc.includes(required), `playtest build doc missing ${required}`);
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
