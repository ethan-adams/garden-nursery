export function traitScore(plantTraits, desiredTraits) {
  return plantTraits.filter((trait) => desiredTraits.includes(trait)).length;
}

export function constraintScore(plant, constraints) {
  const traits = plant.traits ?? [];
  const care = plant.care_needs ?? {};
  const careText = `${care.water ?? ""} ${care.light ?? ""} ${care.difficulty ?? ""}`;
  let score = 0;

  for (const rawConstraint of constraints) {
    const text = String(rawConstraint).toLowerCase();
    if (hasAny(text, ["porch", "step", "bucket"]) && traits.includes("porch-friendly")) score += 1;
    if (hasAny(text, ["shade", "moss", "north"]) && (traits.includes("shade") || traits.includes("damp-tolerant"))) score += 1;
    if (hasAny(text, ["overwater", "damp", "mop", "clay"]) && (traits.includes("damp-tolerant") || careText.includes("moist"))) score += 1;
    if (hasAny(text, ["forget", "neglect", "simple"]) && (traits.includes("low-effort") || traits.includes("hardy") || careText.includes("forgiving"))) score += 1;
    if (hasAny(text, ["children", "school", "stories"]) && (traits.includes("story-rich") || traits.includes("hardy") || traits.includes("pollinator"))) score += 1;
    if (hasAny(text, ["sun"]) && careText.includes("sun")) score += 1;
    if (hasAny(text, ["forget", "neglect", "frost"]) && (traits.includes("tender") || traits.includes("warmth-loving"))) score -= 1;
  }

  return score;
}

export function hintTraitScore(plantTraits, hint) {
  const lowered = hint.toLowerCase();
  let score = 0;
  for (const trait of plantTraits) {
    const words = String(trait).replaceAll("-", " ").toLowerCase().split(" ").filter(Boolean);
    if (words.some((word) => word.length >= 4 && lowered.includes(word))) {
      score += 1;
    }
  }
  return Math.min(score, 2);
}

export function scoreCustomerFit(plant, customer, signal) {
  return scoreCustomerFitForRegion(plant, customer, signal, {});
}

export function scoreCustomerFitForRegion(plant, customer, signal, region) {
  const traits = plant.traits ?? [];
  const price = Number(plant.price ?? 0);
  const budget = Number(customer.budget ?? 0);
  const taste = traitScore(traits, customer.taste ?? []);
  const constraints = constraintScore(plant, customer.garden_constraints ?? []);
  const market = traitScore(traits, signal.points_to_traits ?? []);
  const risk = traitScore(traits, signal.risk_traits ?? []);
  const hint = hintTraitScore(traits, customer.market_hint ?? "");
  const care = careClimateFit(plant, region, signal);
  let budgetScore = -3;
  if (price <= budget) {
    budgetScore = 2;
  } else if (price <= budget + 4) {
    budgetScore = 0;
  }

  return {
    total: (taste * 2) + (constraints * 2) + market + hint + budgetScore + care.score - (risk * 2),
    taste,
    constraints,
    market,
    risk,
    hint,
    budget: budgetScore,
    climate: care.score,
    careSummary: care.summary,
    careWarnings: care.warnings
  };
}

export function customerRecommendationOutcome(plant, customer, fit, remainingStock) {
  const price = Number(plant.price ?? 0);
  const overBudget = price > Number(customer.budget ?? 0) + 4;

  if (remainingStock <= 0) {
    return { sold: false, cash: 0, reputation: 0, reason: "empty_stock" };
  }
  if (overBudget) {
    return { sold: false, cash: 0, reputation: 0, reason: "over_budget" };
  }
  if (fit.total >= 7) {
    return { sold: true, cash: price + 4, reputation: 2, reason: "strong_match" };
  }
  if (fit.total >= 4) {
    return { sold: true, cash: price, reputation: 1, reason: "fair_match" };
  }
  if (fit.total >= 1) {
    return { sold: false, cash: 0, reputation: 0, reason: "teaching_miss" };
  }
  return { sold: false, cash: 0, reputation: -1, reason: "bad_match" };
}

export function recommendPlantToCustomers(plant, customers, signal, startingStock = plant.starting_stock ?? 0) {
  let sold = 0;
  let cash = 0;
  let reputation = 0;
  const outcomes = [];

  for (const customer of customers) {
    const fit = scoreCustomerFit(plant, customer, signal);
    const outcome = customerRecommendationOutcome(plant, customer, fit, startingStock - sold);
    if (outcome.sold) {
      sold += 1;
      cash += outcome.cash;
    }
    reputation += outcome.reputation;
    outcomes.push({ customerId: customer.id, fit, outcome });
  }

  return { sold, cash, reputation, outcomes };
}

export function calendarEntryForWeek(region, week) {
  const calendar = region.season_calendar ?? [];
  if (calendar.length === 0) return null;
  const index = Math.max(0, Math.min(calendar.length - 1, Number(week ?? 1) - 1));
  return calendar[index];
}

export function mergeSignalWithCalendar(signal, region, week) {
  const entry = calendarEntryForWeek(region, week);
  if (!entry) return { ...signal };
  return {
    ...signal,
    source: `${signal.source ?? "market signal"} + ${entry.weather ?? "forecast"}`,
    text: `${signal.text ?? ""}\nForecast: ${entry.forecast ?? ""}`,
    points_to_traits: uniqueStrings([...(signal.points_to_traits ?? []), ...(entry.points_to_traits ?? [])]),
    risk_traits: uniqueStrings([...(signal.risk_traits ?? []), ...(entry.risk_traits ?? [])]),
    uncertainty: Math.max(Number(signal.uncertainty ?? 0), Number(entry.uncertainty ?? 0))
  };
}

export function propagationWeatherAdjustment(plant, region, week) {
  const entry = calendarEntryForWeek(region, week);
  if (!entry) return 0;
  const traits = plant.traits ?? [];
  const bonus = traitScore(traits, entry.propagation_bonus_traits ?? []);
  const risk = traitScore(traits, entry.propagation_risk_traits ?? []);
  return Math.max(-0.18, Math.min(0.16, (bonus * 0.04) - (risk * 0.06)));
}

export function careClimateFit(plant, region = {}, signal = {}) {
  const traits = plant.traits ?? [];
  const climateFit = plant.climate_fit ?? [];
  const care = plant.care_needs ?? {};
  const profile = region.climate_profile ?? {};
  if (Object.keys(profile).length === 0) {
    return { score: 0, summary: "Care fit not yet read.", warnings: [], boosts: [] };
  }
  const regionTraits = region.traits ?? [];
  const warnings = [];
  const boosts = [];
  let score = 0;

  const soilMatches = traitScore(climateFit, profile.soil ?? []);
  if (soilMatches > 0) {
    score += Math.min(2, soilMatches);
    boosts.push("local soil/season fit");
  }
  if (climateFit.includes("temperate") || matchesRegionTrait(climateFit, regionTraits)) {
    score += 1;
    boosts.push("temperate valley fit");
  }

  const water = String(care.water ?? "").toLowerCase();
  if ((profile.water ?? []).some((value) => String(value).toLowerCase() === water)) {
    score += 1;
  } else if (["light", "dry"].includes(water)) {
    score -= 1;
    warnings.push("prefers drier watering than Hush Arbor gives easily");
  }

  const light = String(care.light ?? "").toLowerCase();
  if ((profile.light ?? []).some((value) => String(value).toLowerCase() === light)) {
    score += 1;
  } else if (light.includes("afternoon") || light === "sun") {
    score -= 1;
    warnings.push("needs brighter protection than many porch sites offer");
  }

  const signalRisk = traitScore(traits, signal.risk_traits ?? []);
  if (signalRisk > 0) {
    score -= signalRisk;
    warnings.push("current signal warns against this plant");
  }

  if (traitScore(traits, ["tender", "warmth-loving"]) > 0 && String(profile.frost ?? "").includes("frost")) {
    score -= 1;
    warnings.push("late frost can check it");
  }

  const forgiving = traitScore(traits, profile.forgiving_traits ?? []);
  if (forgiving > 0) {
    score += Math.min(2, forgiving);
    boosts.push("forgiving Hush Arbor habit");
  }

  score = Math.max(-3, Math.min(5, score));
  let summary = "Care fit steady.";
  if (score >= 4) {
    summary = `Care fit is strong: ${boosts.slice(0, 2).join(", ")}.`;
  } else if (score >= 1) {
    summary = "Care fit is workable with a clear tag.";
  } else if (warnings.length > 0) {
    summary = `Care warning: ${warnings[0]}.`;
  }

  return { score, summary, warnings, boosts };
}

function hasAny(text, needles) {
  return needles.some((needle) => text.includes(needle));
}

function matchesRegionTrait(values, regionTraits) {
  return values.some((value) => {
    const normalized = String(value).replaceAll("-", " ").toLowerCase();
    return regionTraits.some((trait) => String(trait).toLowerCase().includes(normalized));
  });
}

function uniqueStrings(values) {
  return [...new Set(values.filter(Boolean).map(String))];
}
