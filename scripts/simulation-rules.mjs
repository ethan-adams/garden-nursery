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
  const traits = plant.traits ?? [];
  const price = Number(plant.price ?? 0);
  const budget = Number(customer.budget ?? 0);
  const taste = traitScore(traits, customer.taste ?? []);
  const constraints = constraintScore(plant, customer.garden_constraints ?? []);
  const market = traitScore(traits, signal.points_to_traits ?? []);
  const risk = traitScore(traits, signal.risk_traits ?? []);
  const hint = hintTraitScore(traits, customer.market_hint ?? "");
  let budgetScore = -3;
  if (price <= budget) {
    budgetScore = 2;
  } else if (price <= budget + 4) {
    budgetScore = 0;
  }

  return {
    total: (taste * 2) + (constraints * 2) + market + hint + budgetScore - (risk * 2),
    taste,
    constraints,
    market,
    risk,
    hint,
    budget: budgetScore
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

function hasAny(text, needles) {
  return needles.some((needle) => text.includes(needle));
}
