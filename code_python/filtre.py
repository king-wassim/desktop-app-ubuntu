import os
import re
import ast
from typing import List
import json

def load_rules(rules_file: str) -> List[str]:
    with open(rules_file, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]

def extract_metadata_from_file(filepath: str) -> dict:
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = r"@pytest\.mark\.metadata\s*\(\s*(.*?)\s*\)\s*"
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return {}

    metadata_str = match.group(1)

    # Convertir les clés = valeurs en dictionnaire Python valide
    metadata_str = re.sub(r'(\w+)\s*=', r'"\1":', metadata_str)

    try:
        metadata_dict = ast.literal_eval("{" + metadata_str + "}")
    except Exception as e:
        print(f"Erreur lors de la conversion des metadata dans {filepath}: {e}")
        return {}

    return metadata_dict

def check_file_with_rules(data: dict, rules_lines: List[str]) -> bool:
    for line in rules_lines:
        parts = line.split(";")
        if len(parts) < 2:
            continue
        key = parts[0].strip()
        # Retirer "metadata:" si présent
        if key.startswith("metadata:"):
            key = key[len("metadata:"):]

        value_str = parts[1].strip()
        if value_str.lower() == "any":
            continue

        try:
            expected_value = ast.literal_eval(value_str)
        except Exception:
            expected_value = value_str

        if key not in data:
            return False

        actual_value = data[key]

        if isinstance(expected_value, list):
            if isinstance(actual_value, list):
                if not all(item in actual_value for item in expected_value):
                    return False
            else:
                if expected_value[0] != actual_value:
                    return False
        else:
            if expected_value != actual_value:
                return False
    return True


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python filtre.py <target_folder_or_file> <rules_file>")
        sys.exit(1)

    target = sys.argv[1]
    rules_file = sys.argv[2]

    rules_lines = load_rules(rules_file)
    file_filtered = []

    if os.path.isdir(target):
        for root, _, files in os.walk(target):
            for f in files:
                if f.endswith(".py") and f.startswith("test"):
                    file_path = os.path.join(root, f)
                    data = extract_metadata_from_file(file_path)
                    if check_file_with_rules(data, rules_lines):
                        file_filtered.append(file_path)
    elif target.endswith('.py') and os.path.basename(target).startswith("test"):
        data = extract_metadata_from_file(target)
        if check_file_with_rules(data, rules_lines):
            file_filtered.append(target)
    else:
        print("Aucun fichier .py commençant par 'test' trouvé.")
        sys.exit(1)

    print(json.dumps(file_filtered))
