import os

def delete_linting_result(file_path: str) -> None:
    """
    Supprime le fichier 'black_flake.txt' situé dans le même répertoire que le fichier donné.
    """
    output_dir = os.path.dirname(file_path)
    result_file_black = os.path.join(output_dir, "black_flake_warning.txt")

    if os.path.exists(result_file_black )  :
        os.remove(result_file_black )
        print(f"Fichier supprimé : {result_file_black }")
    else:
        print("Aucun fichier 'black_flake.txt' à supprimer.")

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
        delete_linting_result(path)

