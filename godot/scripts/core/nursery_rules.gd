class_name NurseryRules
extends RefCounted


static func score_customer_fit(plant: Dictionary, customer: Dictionary, signal_data: Dictionary) -> Dictionary:
	var traits: Array = plant.get("traits", [])
	var price := int(plant.get("price", 0))
	var budget := int(customer.get("budget", 0))
	var taste_score := trait_score(traits, customer.get("taste", []))
	var constraint_fit := constraint_score(plant, customer.get("garden_constraints", []))
	var market_score := trait_score(traits, signal_data.get("points_to_traits", []))
	var risk_score := trait_score(traits, signal_data.get("risk_traits", []))
	var hint_score := hint_trait_score(traits, customer.get("market_hint", ""))
	var budget_score := 0
	if price <= budget:
		budget_score = 2
	elif price <= budget + 4:
		budget_score = 0
	else:
		budget_score = -3
	var total := (taste_score * 2) + (constraint_fit * 2) + market_score + hint_score + budget_score - (risk_score * 2)
	return {
		"total": total,
		"taste": taste_score,
		"constraints": constraint_fit,
		"market": market_score,
		"risk": risk_score,
		"hint": hint_score,
		"budget": budget_score
	}


static func customer_recommendation_outcome(plant: Dictionary, customer: Dictionary, fit: Dictionary, remaining_stock: int) -> Dictionary:
	var customer_name: String = customer.get("display_name", "Customer")
	var price := int(plant.get("price", 0))
	var total := int(fit.get("total", 0))
	var over_budget := price > int(customer.get("budget", 0)) + 4
	if remaining_stock <= 0:
		return {
			"sold": false,
			"cash": 0,
			"reputation": 0,
			"line": "%s: interested, but the bench was empty." % customer_name,
			"note": "remembered the missing stock"
		}
	if over_budget:
		return {
			"sold": false,
			"cash": 0,
			"reputation": 0,
			"line": "%s: passed; %s strained the $%d budget." % [customer_name, plant.get("name", "it"), int(customer.get("budget", 0))],
			"note": "budget matters more than the prettiest tag"
		}
	if total >= 7:
		return {
			"sold": true,
			"cash": price + 4,
			"reputation": 2,
			"line": "%s: sold gladly. Taste, site, and signal all lined up." % customer_name,
			"note": "trusted the %s recommendation" % plant.get("name", "plant")
		}
	if total >= 4:
		return {
			"sold": true,
			"cash": price,
			"reputation": 1,
			"line": "%s: sold after a care warning. Good enough, not perfect." % customer_name,
			"note": "accepted %s with a care warning" % plant.get("name", "the plant")
		}
	if total >= 1:
		return {
			"sold": false,
			"cash": 0,
			"reputation": 0,
			"line": "%s: did not buy, but learned why %s was a maybe." % [customer_name, plant.get("name", "it")],
			"note": "appreciated the honest maybe"
		}
	return {
		"sold": false,
		"cash": 0,
		"reputation": -1,
		"line": "%s: walked away; the recommendation fought the garden." % customer_name,
		"note": "will need a better fit next time"
	}


static func best_outcome_for(plant: Dictionary, outcomes: Array) -> Dictionary:
	var best := {}
	var best_score := -1
	for outcome in outcomes:
		var score := trait_score(plant.get("traits", []), outcome.get("trigger_traits", []))
		if score > best_score:
			best = outcome
			best_score = score
	return best


static func trait_score(plant_traits: Array, desired_traits: Array) -> int:
	var score := 0
	for plant_trait in plant_traits:
		if desired_traits.has(plant_trait):
			score += 1
	return score


static func constraint_score(plant: Dictionary, constraints: Array) -> int:
	var score := 0
	var traits: Array = plant.get("traits", [])
	var care_needs: Dictionary = plant.get("care_needs", {})
	var care_text := "%s %s %s" % [
		care_needs.get("water", ""),
		care_needs.get("light", ""),
		care_needs.get("difficulty", "")
	]
	for constraint in constraints:
		var text := String(constraint).to_lower()
		if _has_any(text, ["porch", "step", "bucket"]) and traits.has("porch-friendly"):
			score += 1
		if _has_any(text, ["shade", "moss", "north"]) and (traits.has("shade") or traits.has("damp-tolerant")):
			score += 1
		if _has_any(text, ["overwater", "damp", "mop", "clay"]) and (traits.has("damp-tolerant") or care_text.contains("moist")):
			score += 1
		if _has_any(text, ["forget", "neglect", "simple"]) and (traits.has("low-effort") or traits.has("hardy") or care_text.contains("forgiving")):
			score += 1
		if _has_any(text, ["children", "school", "stories"]) and (traits.has("story-rich") or traits.has("hardy") or traits.has("pollinator")):
			score += 1
		if _has_any(text, ["sun"]) and care_text.contains("sun"):
			score += 1
		if _has_any(text, ["forget", "neglect", "frost"]) and (traits.has("tender") or traits.has("warmth-loving")):
			score -= 1
	return score


static func hint_trait_score(plant_traits: Array, hint: String) -> int:
	var score := 0
	var lowered := hint.to_lower()
	for plant_trait in plant_traits:
		var normalized := String(plant_trait).replace("-", " ").to_lower()
		for word in normalized.split(" ", false):
			if word.length() >= 4 and lowered.contains(word):
				score += 1
				break
	return min(score, 2)


static func _has_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false
