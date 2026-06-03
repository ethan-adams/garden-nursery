import { readFile } from "node:fs/promises";

const catalogs = [
  {
    path: "godot/data/plants/starter_plants.json",
    root: "plants",
    required: ["id", "name", "category", "price", "starting_stock", "traits", "climate_fit", "care_needs", "market_notes"]
  },
  {
    path: "godot/data/customers/hush_arbor_archetypes.json",
    root: "customers",
    required: ["id", "display_name", "role", "budget", "garden_constraints", "taste", "contradiction", "market_hint"]
  },
  {
    path: "godot/data/regions/hush_arbor.json",
    root: "market_signals",
    required: ["id", "source", "text", "points_to_traits", "risk_traits", "uncertainty"]
  },
  {
    path: "godot/data/dialogue/writing_sample_pack.json",
    root: "customer_barks",
    required: []
  }
];

function fail(message) {
  console.error(message);
  process.exitCode = 1;
}

for (const catalog of catalogs) {
  let parsed;
  try {
    parsed = JSON.parse(await readFile(catalog.path, "utf8"));
  } catch (error) {
    fail(`${catalog.path}: invalid JSON (${error.message})`);
    continue;
  }

  const entries = parsed[catalog.root];
  if (!Array.isArray(entries)) {
    fail(`${catalog.path}: expected array at "${catalog.root}"`);
    continue;
  }

  if (entries.length === 0) {
    fail(`${catalog.path}: "${catalog.root}" must not be empty`);
    continue;
  }

  entries.forEach((entry, index) => {
    const label = entry.id ?? `${catalog.root}[${index}]`;
    for (const field of catalog.required) {
      if (!Object.hasOwn(entry, field)) {
        fail(`${catalog.path}: ${label} missing required field "${field}"`);
      }
    }
  });
}

if (!process.exitCode) {
  console.log("ok - data catalogs validate");
}
