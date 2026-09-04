from __future__ import annotations

import re
import unittest
from pathlib import Path
from urllib.parse import unquote


PROJECT_ROOT = Path(__file__).resolve().parents[1]


class PublicRepositoryTests(unittest.TestCase):
    def test_required_public_repository_files_exist(self) -> None:
        required = (
            ".gitignore",
            "README.md",
            "LICENSE",
            "SECURITY.md",
            "CONTRIBUTING.md",
            "CODE_OF_CONDUCT.md",
            "docs/Project-Overview.md",
            "docs/Implementation-Plan.md",
            "docs/Project-Implementation-Plan.md",
            "docs/Product-Brief.md",
            "docs/Decision-Log.md",
            ".github/pull_request_template.md",
            ".github/ISSUE_TEMPLATE/config.yml",
            ".github/ISSUE_TEMPLATE/bug_report.yml",
            ".github/ISSUE_TEMPLATE/feature_request.yml",
            ".github/workflows/ci.yml",
            "scripts/verify-repository.sh",
        )

        missing = [path for path in required if not (PROJECT_ROOT / path).is_file()]
        self.assertEqual(missing, [])

    def test_readme_is_honest_about_planning_status(self) -> None:
        readme = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

        for statement in (
            "Project status:** Planning",
            "No application, package, hosted service, or supported release exists yet",
            "calm, uninterrupted factual narration",
            "does not claim subconscious learning",
            "./scripts/verify-repository.sh",
            "SECURITY.md",
            "MIT License",
        ):
            with self.subTest(statement=statement):
                self.assertIn(statement, readme)

    def test_product_context_and_roadmap_preserve_key_boundaries(self) -> None:
        brief = (PROJECT_ROOT / "docs/Product-Brief.md").read_text(encoding="utf-8")
        project_plan = (
            PROJECT_ROOT / "docs/Project-Implementation-Plan.md"
        ).read_text(encoding="utf-8")
        decisions = (PROJECT_ROOT / "docs/Decision-Log.md").read_text(
            encoding="utf-8"
        )

        for statement in (
            "Helping the listener relax and fall asleep is the primary purpose",
            "played**, not learned, mastered, or retained",
            "Once playback starts, the route is fixed",
            "No backend, accounts, analytics, cloud sync, subscriptions, ads",
            "approximately ten real naps",
        ):
            with self.subTest(document="product brief", statement=statement):
                self.assertIn(statement, brief)

        for statement in (
            "spike/audio-and-alarm-feasibility",
            "feature/nap-plan-domain",
            "feature/nap-playback-runtime",
            "validation/ten-nap-trial",
            "Physical-device acceptance",
        ):
            with self.subTest(
                document="project implementation plan", statement=statement
            ):
                self.assertIn(statement, project_plan)

        for decision_id in ("D-001", "D-003", "D-004", "D-010", "D-017"):
            with self.subTest(document="decision log", decision_id=decision_id):
                self.assertIn(decision_id, decisions)

    def test_durable_project_plan_is_distinct_from_replaceable_task_plan(self) -> None:
        readme = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
        overview = (PROJECT_ROOT / "docs/Project-Overview.md").read_text(
            encoding="utf-8"
        )

        self.assertIn("docs/Project-Implementation-Plan.md", readme)
        self.assertIn("docs/Implementation-Plan.md", readme)
        self.assertIn("Task plans may be overwritten", overview)

    def test_privacy_sensitive_artifacts_are_ignored(self) -> None:
        ignore = (PROJECT_ROOT / ".gitignore").read_text(encoding="utf-8")

        for pattern in (
            ".env",
            "*.key",
            "*.pem",
            "credentials*.json",
            "secrets*.json",
            "/local-data/",
            "/reports/",
            "*.sqlite",
            "*.log",
        ):
            with self.subTest(pattern=pattern):
                self.assertIn(pattern, ignore)

    def test_ci_uses_read_only_pinned_quota_aware_workflow(self) -> None:
        workflow = (PROJECT_ROOT / ".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )

        self.assertIn("pull_request:", workflow)
        self.assertIn("workflow_dispatch:", workflow)
        self.assertNotRegex(workflow, r"(?m)^  push:")
        self.assertIn("contents: read", workflow)
        self.assertIn("persist-credentials: false", workflow)
        self.assertRegex(workflow, r"actions/checkout@[0-9a-f]{40}")
        self.assertIn("cancel-in-progress: true", workflow)

    def test_markdown_relative_links_resolve(self) -> None:
        broken: list[str] = []
        link_pattern = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")

        for markdown in PROJECT_ROOT.rglob("*.md"):
            if ".git" in markdown.parts:
                continue
            content = markdown.read_text(encoding="utf-8")
            for target in link_pattern.findall(content):
                cleaned = target.strip().split()[0].strip("<>")
                if cleaned.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                relative = unquote(cleaned.split("#", 1)[0])
                if relative and not (markdown.parent / relative).exists():
                    broken.append(f"{markdown.relative_to(PROJECT_ROOT)} -> {target}")

        self.assertEqual(broken, [])

    def test_working_tree_has_no_common_private_or_generated_artifacts(self) -> None:
        forbidden_names = {
            ".DS_Store",
            "Local.xcconfig",
            "Secrets.xcconfig",
        }
        forbidden_suffixes = {
            ".key",
            ".pem",
            ".p8",
            ".p12",
            ".pfx",
            ".mobileprovision",
            ".sqlite",
            ".sqlite3",
            ".db",
            ".log",
        }
        offenders: list[str] = []

        for path in PROJECT_ROOT.rglob("*"):
            if ".git" in path.parts or not path.is_file():
                continue
            if path.name in forbidden_names or path.suffix.lower() in forbidden_suffixes:
                offenders.append(str(path.relative_to(PROJECT_ROOT)))

        self.assertEqual(offenders, [])


if __name__ == "__main__":
    unittest.main()
