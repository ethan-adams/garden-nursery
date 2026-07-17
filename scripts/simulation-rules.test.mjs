import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import {
  careClimateFit,
  calendarEntryForWeek,
  constraintScore,
  customerRecommendationOutcome,
  mergeSignalWithCalendar,
  propagationWeatherAdjustment,
  recommendPlantToCustomers,
  scoreCustomerFitForRegion,
  scoreCustomerFit,
  traitScore
} from "./simulation-rules.mjs";

const plants = (await readJson("godot/data/plants/starter_plants.json")).plants;
const customers = (await readJson("godot/data/customers/hush_arbor_archetypes.json")).customers;
const region = await readJson("godot/data/regions/hush_arbor.json");

const byId = (items, id) => items.find((item) => item.id === id);

const hushChives = byId(plants, "hush_chives");
const lanternTomato = byId(plants, "lantern_tomato");
const chimneyFern = byId(plants, "chimney_fern");
const thresholdAloe = byId(plants, "threshold_aloe");
const mara = byId(customers, "mara_lye");
const cilla = byId(customers, "cilla_park");
const frostSignal = byId(region.market_signals, "weather_board_frost");
const shadeSignal = byId(region.market_signals, "porch_chatter_shade");
const weekOneWeather = calendarEntryForWeek(region, 1);
const mergedFrostSignal = mergeSignalWithCalendar(frostSignal, region, 1);

assert.equal(weekOneWeather.weather, "mild frost", "week one should start with the Hush Arbor frost beat");

const yearLength = region.season_calendar.length;
assert.ok(yearLength >= 20, "Hush Arbor should have a full-year weekly calendar");
assert.deepEqual(
  calendarEntryForWeek(region, yearLength + 1),
  weekOneWeather,
  "the calendar should wrap back to week one when the year rolls over"
);
const seasonFamilies = new Set(region.season_calendar.map((entry) => entry.season.split(" ").at(-1)));
for (const family of ["spring", "summer", "autumn", "winter"]) {
  assert.ok(seasonFamilies.has(family), `the year should pass through ${family}`);
}
const midwinter = calendarEntryForWeek(region, 21);
assert.equal(midwinter.season.split(" ").at(-1), "winter", "late-year weeks should reach winter instead of freezing on autumn");
assert.ok(mergedFrostSignal.points_to_traits.includes("cool-spring"), "calendar forecasts should add demand traits to market signals");
assert.ok(mergedFrostSignal.risk_traits.includes("warmth-loving"), "calendar forecasts should add weather risk traits to market signals");
assert.ok(mergedFrostSignal.text.includes("Forecast:"), "merged market signals should show forecast uncertainty in-world");

assert.equal(traitScore(hushChives.traits, frostSignal.points_to_traits), 2, "hardy early-spring plants should match frost signal traits");
assert.equal(traitScore(lanternTomato.traits, frostSignal.risk_traits), 2, "tender warmth-loving plants should hit frost risk traits");

const chivesForMara = scoreCustomerFit(hushChives, mara, frostSignal);
const tomatoForMara = scoreCustomerFit(lanternTomato, mara, frostSignal);
assert.ok(chivesForMara.total > tomatoForMara.total, "risk traits should make early tomatoes score worse than hardy chives during frost gossip");
assert.ok(chivesForMara.taste > 0, "customer taste should contribute to recommendation fit");
assert.ok(chivesForMara.constraints > 0, "garden constraints should contribute to recommendation fit");

const chivesCare = careClimateFit(hushChives, region, frostSignal);
const tomatoCare = careClimateFit(lanternTomato, region, frostSignal);
assert.ok(chivesCare.score > 0, "hardy cool-spring herbs should fit Hush Arbor's early climate");
assert.ok(tomatoCare.score < chivesCare.score, "tender warmth-loving tomatoes should carry more climate risk during frost gossip");
assert.ok(tomatoCare.warnings.length > 0, "climate-risk plants should explain why they may struggle");
const regionalChivesForMara = scoreCustomerFitForRegion(hushChives, mara, frostSignal, region);
const regionalTomatoForMara = scoreCustomerFitForRegion(lanternTomato, mara, frostSignal, region);
assert.ok(regionalChivesForMara.climate > regionalTomatoForMara.climate, "regional scoring should include care and climate fit");
assert.ok(
  propagationWeatherAdjustment(hushChives, region, 1) > propagationWeatherAdjustment(lanternTomato, region, 1),
  "mild frost should help hardy propagation more than tender warm-season trays"
);

const fernForCilla = scoreCustomerFit(chimneyFern, cilla, shadeSignal);
const aloeForCilla = scoreCustomerFit(thresholdAloe, cilla, shadeSignal);
assert.ok(constraintScore(chimneyFern, cilla.garden_constraints) > 0, "shade and damp constraints should recognize chimney fern");
assert.ok(fernForCilla.total > aloeForCilla.total, "a shade porch plant should beat a frost-tender bright-window plant for Cilla");

const tightBudgetCustomer = {
  ...mara,
  budget: 3
};
const overBudgetOutcome = customerRecommendationOutcome(hushChives, tightBudgetCustomer, scoreCustomerFit(hushChives, tightBudgetCustomer, frostSignal), 1);
assert.deepEqual(
  pick(overBudgetOutcome, ["sold", "cash", "reputation", "reason"]),
  { sold: false, cash: 0, reputation: 0, reason: "over_budget" },
  "plants more than $4 over budget should not sell or punish reputation"
);

const strongOutcome = customerRecommendationOutcome(hushChives, mara, chivesForMara, 1);
assert.equal(strongOutcome.reason, "strong_match", "strong fits should be called out as strong matches");
assert.equal(strongOutcome.reputation, 2, "strong fits should increase reputation");

const poorFit = scoreCustomerFit(lanternTomato, cilla, frostSignal);
const poorOutcome = customerRecommendationOutcome(lanternTomato, cilla, poorFit, 1);
assert.equal(poorOutcome.sold, false, "bad fits should not sell");
assert.equal(poorOutcome.reputation, -1, "bad fits should cost a small amount of trust");

const groupResult = recommendPlantToCustomers(hushChives, customers, frostSignal, hushChives.starting_stock);
assert.ok(groupResult.sold >= 1, "a good starter recommendation should sell to at least one regular");
assert.equal(
  groupResult.reputation,
  groupResult.outcomes.reduce((sum, entry) => sum + entry.outcome.reputation, 0),
  "group recommendation reputation should equal the sum of customer outcomes"
);

console.log("ok - simulation rule tests passed");

async function readJson(path) {
  return JSON.parse(await readFile(path, "utf8"));
}

function pick(object, keys) {
  return Object.fromEntries(keys.map((key) => [key, object[key]]));
}
