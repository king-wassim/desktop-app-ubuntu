import os
import subprocess
from TestLoopControlAssertion import run_ast_rule_checker
def run_linting_tools(file_path: str) -> None:
    output_dir = os.path.dirname(file_path)
    result_file = os.path.join(output_dir, "black_flake_warning.txt")

    with open(result_file, "w", encoding="utf-8") as out_file:
        out_file.write("\n"+"="*50+"Black result" +"="*50+"\n")

    # On ouvre en mode 'a' pour ajouter sans écraser
    with open(result_file, "a", encoding="utf-8") as out_file:
        subprocess.run(
            ["black", "--check", "--diff", file_path],
            stdout=out_file,
            stderr=subprocess.STDOUT
        )
    with open(result_file, "a", encoding="utf-8") as out_file:
        out_file.write("" + "=" * 180 + "\n")
        #out_file.write("" + "=" * 180 + "\n")
        out_file.write("\n"+"="*50+"Flake8 result" +"="*50+"\n")

    with open(result_file, "a", encoding="utf-8") as out_file:
        subprocess.run(
            ["flake8","--ignore=E501", file_path],
            stdout=out_file,
            stderr=subprocess.STDOUT
        )

    # 3️⃣ Directement append résultat AST
    run_ast_rule_checker(file_path, result_file)

if __name__ == "__main__":
    import sys
    target = sys.argv[1]
    paths = []
    if os.path.isdir(target):
        for root, _, files in os.walk(target):
            for f in files:
                if f.endswith(".py") and f.startswith("test"):
                    paths.append(os.path.join(root, f))
    elif target.endswith('.py') and os.path.basename(target).startswith("test"):
        paths.append(target)
    else:
        print("Aucun fichier .py commençant par 'test' trouvé.")
        sys.exit(1)
    for i, path in enumerate(paths, start=1):
        run_linting_tools(path)
        
