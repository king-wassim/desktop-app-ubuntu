from typing import Dict, Any

def load_validation_rules(rules_file: str) -> Dict[str, Dict[str, Any]]:
    rules = {}
    with open(rules_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split(";")
            rule = {}
            for part in parts[1:]:
                key, value = part.split(":", 1)
                key, value = key.strip().lower(), value.strip()
                if key == "mandatory":
                    rule["mandatory"] = value.lower() == "yes"
                elif key == "type":
                    rule["type"] = value.lower()
                elif key == "possible values":
                    if value == "any":
                        rule["values"] = None
                    else:
                        vals = value.split(",")
                        if rule.get("type") == "integer":
                            rule["values"] = [int(v) for v in vals]
                        elif rule.get("type") == "boolean":
                            rule["values"] = [v.strip().lower() for v in vals]
                        else:
                            rule["values"] = [v.strip() for v in vals]
            rules[parts[0].strip()] = rule
    return rules
