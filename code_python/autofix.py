import subprocess
import os 
def run_autoflake_and_black(file_path: str):
    # 1️⃣ Suppression des imports/variables inutilisés
    subprocess.run([
        "autoflake", "--in-place", 
        "--remove-unused-variables", 
        "--remove-all-unused-imports", 
        file_path
    ])  
    # 2️⃣ Correction PEP8 agressive
    subprocess.run([
        "autopep8", "--in-place", "--aggressive", "--aggressive", file_path
    ])
    # 3️⃣ Formatage Black (réécriture complète)
    subprocess.run(["black", file_path])


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
        run_autoflake_and_black(path)
    
