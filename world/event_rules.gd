extends RefCounted
# Conditions are data; execution, transactions and presentation stay with their owning services.
static func condition(rule: Dictionary,facts: Dictionary) -> bool:
	if not facts.has(rule.fact):return false
	if rule.has("equals"):return facts[rule.fact]==rule.equals
	if rule.has("less_than"):return float(facts[rule.fact])<float(rule.less_than)
	return false
static func eligible(event: Dictionary,facts: Dictionary) -> bool:
	for rule in event.get("all",[]):
		if not condition(rule,facts):return false
	var alternatives: Array=event.get("any",[])
	if alternatives.is_empty():return true
	for rule in alternatives:
		if condition(rule,facts):return true
	return false
