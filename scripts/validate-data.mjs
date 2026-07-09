import { readFile } from "node:fs/promises";

const catalogs = [
  {
    path: "godot/data/plants/starter_plants.json",
    root: "plants",
    required: ["id", "name", "category", "price", "starting_stock", "traits", "climate_fit", "care_needs", "market_notes"],
    count: { min: 12, max: 20 },
    nested: {
      care_needs: ["water", "light", "difficulty"],
      propagation: ["method", "weeks", "cost", "yield", "success_chance", "notes"]
    }
  },
  {
    path: "godot/data/customers/hush_arbor_archetypes.json",
    root: "customers",
    required: ["id", "display_name", "role", "budget", "garden_constraints", "taste", "contradiction", "market_hint", "returning_beats"],
    nested: {
      returning_beats: ["trust_up", "careful", "trust_down"]
    }
  },
  {
    path: "godot/data/regions/hush_arbor.json",
    root: "market_signals",
    required: ["id", "source", "text", "points_to_traits", "risk_traits", "uncertainty"],
    documentRequired: ["climate_profile", "season_calendar"],
    documentNested: {
      climate_profile: ["water", "light", "soil", "frost", "heat", "forgiving_traits", "risk_traits"]
    },
    arrays: {
      season_calendar: ["week", "season", "weather", "forecast", "points_to_traits", "risk_traits", "propagation_bonus_traits", "propagation_risk_traits", "uncertainty"]
    }
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
  for (const field of catalog.documentRequired ?? []) {
    if (!Object.hasOwn(parsed, field)) {
      fail(`${catalog.path}: missing required field "${field}"`);
    }
  }
  for (const [field, requiredFields] of Object.entries(catalog.documentNested ?? {})) {
    const value = parsed[field];
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      fail(`${catalog.path}: missing required object "${field}"`);
      continue;
    }
    for (const nestedField of requiredFields) {
      if (!Object.hasOwn(value, nestedField)) {
        fail(`${catalog.path}: ${field} missing required field "${nestedField}"`);
      }
    }
  }
  for (const [field, requiredFields] of Object.entries(catalog.arrays ?? {})) {
    const values = parsed[field];
    if (!Array.isArray(values) || values.length === 0) {
      fail(`${catalog.path}: expected non-empty array "${field}"`);
      continue;
    }
    values.forEach((entry, index) => {
      for (const requiredField of requiredFields) {
        if (!Object.hasOwn(entry, requiredField)) {
          fail(`${catalog.path}: ${field}[${index}] missing required field "${requiredField}"`);
        }
      }
    });
  }

  if (!Array.isArray(entries)) {
    fail(`${catalog.path}: expected array at "${catalog.root}"`);
    continue;
  }

  if (entries.length === 0) {
    fail(`${catalog.path}: "${catalog.root}" must not be empty`);
    continue;
  }

  if (catalog.count?.min && entries.length < catalog.count.min) {
    fail(`${catalog.path}: expected at least ${catalog.count.min} entries, found ${entries.length}`);
  }

  if (catalog.count?.max && entries.length > catalog.count.max) {
    fail(`${catalog.path}: expected no more than ${catalog.count.max} entries, found ${entries.length}`);
  }

  const seenIds = new Set();
  entries.forEach((entry, index) => {
    const label = entry.id ?? `${catalog.root}[${index}]`;
    if (entry.id) {
      if (seenIds.has(entry.id)) {
        fail(`${catalog.path}: duplicate id "${entry.id}"`);
      }
      seenIds.add(entry.id);
    }
    for (const field of catalog.required) {
      if (!Object.hasOwn(entry, field)) {
        fail(`${catalog.path}: ${label} missing required field "${field}"`);
      }
    }

    for (const [field, requiredFields] of Object.entries(catalog.nested ?? {})) {
      const value = entry[field];
      if (!value || typeof value !== "object" || Array.isArray(value)) {
        fail(`${catalog.path}: ${label} missing required object "${field}"`);
        continue;
      }

      for (const nestedField of requiredFields) {
        if (!Object.hasOwn(value, nestedField)) {
          fail(`${catalog.path}: ${label}.${field} missing required field "${nestedField}"`);
        }
      }
    }
  });
}

if (!process.exitCode) {
  console.log("ok - data catalogs validate");
}
