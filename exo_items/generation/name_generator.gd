extends RefCounted
static func compose(profile: Dictionary, material: Dictionary, affixes: Array) -> String:
 var name_value: String = str(profile.get("name", "Objeto"))
 var before: String = ""
 var after: String = ""
 for a in affixes:
  if str(a.get("slot", "")) == "prefix" and before.is_empty(): before = _gender(str(a.display), str(profile.get("gender", "f")))
  elif str(a.get("slot", "")) == "suffix" and after.is_empty(): after = str(a.display)
 if not before.is_empty(): name_value += " " + before
 if str(material.get("id", "")) != "plain" and str(material.get("id", "")) != "raw": name_value += " de " + str(material.name)
 if not after.is_empty(): name_value += " " + after
 return name_value
static func _gender(word: String, gender: String) -> String:
 if gender == "m":
  if word.ends_with("ã"): return word.substr(0, word.length() - 1) + "ão"
  if word.ends_with("a"): return word.substr(0, word.length() - 1) + "o"
 return word
