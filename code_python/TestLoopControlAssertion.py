import ast
import os 

class TestRuleChecker(ast.NodeVisitor):
    def __init__(self, file_path):
        self.file_path = file_path
        self.warnings = []

    def visit_ClassDef(self, node):
        if node.name.startswith("Test"):
            for body_item in node.body:
                if isinstance(body_item, (ast.For, ast.While, ast.If, ast.Try, ast.With)):
                    self.warnings.append(
                        f"{self.file_path}:ligne {body_item.lineno}  Boucle ou contrôle interdit dans une classe de test (niveau classe)."
                    )

                if isinstance(body_item, ast.FunctionDef):
                    is_teardown = body_item.name.lower().startswith("teardown")

                    for stmt in ast.walk(body_item):
                        if isinstance(stmt, (ast.For, ast.While, ast.If, ast.Try, ast.With)):
                            self.warnings.append(
                                f"{self.file_path}:ligne {stmt.lineno}  Boucle ou contrôle interdit dans une méthode de la classe."
                            )

                        if is_teardown:
                            if isinstance(stmt, ast.Assert) or (
                                isinstance(stmt, ast.Expr)
                                and isinstance(stmt.value, ast.Call)
                                and isinstance(stmt.value.func, ast.Attribute)
                                and "assert" in stmt.value.func.attr.lower()
                            ) or isinstance(stmt, (ast.For, ast.While, ast.If, ast.Try, ast.With)):
                                self.warnings.append(
                                    f"{self.file_path}:ligne {stmt.lineno}  Assertion interdite dans tearDown()."
                                )

                    for i, stmt in enumerate(body_item.body):
                        if (
                            isinstance(stmt, ast.Expr)
                            and isinstance(stmt.value, ast.Call)
                            and isinstance(stmt.value.func, ast.Name)
                            and stmt.value.func.id == "step"
                        ):
                            next_stmt = body_item.body[i + 1] if i + 1 < len(body_item.body) else None
                            if not next_stmt or not self._is_assert_or_expect(next_stmt):
                                self.warnings.append(
                                    f"{self.file_path}:ligne {stmt.lineno}  Le step() n'est pas suivi d'un assert ou expect."
                                )
        self.generic_visit(node)

    def _is_assert_or_expect(self, stmt):
        return (
            isinstance(stmt, ast.Assert)
            or (
                isinstance(stmt, ast.Expr)
                and isinstance(stmt.value, ast.Call)
                and isinstance(stmt.value.func, ast.Attribute)
                and (
                    "assert" in stmt.value.func.attr.lower()
                    or "expect" in stmt.value.func.attr.lower()
                )
            )
        )


def run_ast_rule_checker(file_path: str, output_file: str) -> None:
    with open(file_path, "r", encoding="utf-8") as f:
        tree = ast.parse(f.read(), filename=file_path)
    checker = TestRuleChecker(file_path)
    checker.visit(tree)

    with open(output_file, "a", encoding="utf-8") as wf:
        wf.write("\n" + "=" * 180 + "")
        #wf.write("\n" + "=" * 180 + "")
        wf.write("\n"+"="*50+" Warnings" +"="*50+"\n")
        
        if checker.warnings:
            wf.write("\n".join(checker.warnings))
        else:
            wf.write("Aucune violation détectée.")

    print(f" Analyse AST terminée pour {file_path} -> Résultat : {output_file}")
