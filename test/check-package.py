#!/usr/bin/env python3
"""Dependency-free consistency checks for the published skill package."""

from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "plugins" / "exasol" / "skills"
ROUTER = SKILLS / "exasol" / "SKILL.md"
COMMANDS = sorted((ROOT / "plugins" / "exasol" / "commands").glob("*.md"))
REFERENCE_FILES = sorted(SKILLS.glob("*/references/*.md"))
README = ROOT / "README.md"
WORKFLOWS = sorted((ROOT / ".github" / "workflows").glob("*.yml"))
errors: list[str] = []


def frontmatter(path: Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        errors.append(f"{path.relative_to(ROOT)} has no YAML front matter")
        return {}
    try:
        end = lines.index("---", 1)
    except ValueError:
        errors.append(f"{path.relative_to(ROOT)} has unterminated YAML front matter")
        return {}
    result: dict[str, str] = {}
    for line in lines[1:end]:
        match = re.match(r"^([a-zA-Z0-9_-]+):\s*(.*)$", line)
        if match:
            key = match.group(1)
            if key in result:
                errors.append(
                    f"{path.relative_to(ROOT)} has duplicate front-matter key {key!r}"
                )
            result[key] = match.group(2).strip().strip('"\'')
    return result


def load_json(path: Path) -> dict:
    def reject_duplicates(pairs: list[tuple[str, object]]) -> dict:
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"duplicate key {key!r}")
            result[key] = value
        return result

    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicates)
    except (json.JSONDecodeError, ValueError) as exception:
        errors.append(f"{path.relative_to(ROOT)} is invalid: {exception}")
        return {}


skill_names: dict[str, Path] = {}
for skill_file in sorted(SKILLS.glob("*/SKILL.md")):
    metadata = frontmatter(skill_file)
    name = metadata.get("name", "")
    description = metadata.get("description", "")
    expected = skill_file.parent.name
    if not name:
        errors.append(f"{skill_file.relative_to(ROOT)} has no front-matter name")
    elif name != expected:
        errors.append(
            f"{skill_file.relative_to(ROOT)} name {name!r} does not match expected {expected!r}"
        )
    elif name in skill_names:
        errors.append(
            f"duplicate skill name {name!r} in "
            f"{skill_names[name].relative_to(ROOT)} and {skill_file.relative_to(ROOT)}"
        )
    else:
        skill_names[name] = skill_file
    if not description:
        errors.append(f"{skill_file.relative_to(ROOT)} has no front-matter description")

    skill_text = skill_file.read_text(encoding="utf-8")
    packaged_references = {
        path.relative_to(skill_file.parent).as_posix()
        for path in (skill_file.parent / "references").glob("*.md")
    }
    load_references = set(
        re.findall(r"^.*Load:.*?(references/[a-zA-Z0-9._/-]+\.md)", skill_text, re.MULTILINE)
    )
    for relative_path in sorted(load_references - packaged_references):
        errors.append(
            f"{skill_file.relative_to(ROOT)} loads missing reference {relative_path}"
        )
    routed_references = {
        relative_path
        for relative_path in packaged_references
        if relative_path in skill_text
    }
    for relative_path in sorted(packaged_references - routed_references):
        errors.append(
            f"{skill_file.parent.relative_to(ROOT) / relative_path} is not routed by its SKILL.md"
        )

# The contributor skeleton lives beside the skills it is copied from, but it must
# not be one: any directory under skills/ holding a SKILL.md is discovered as a
# real skill and shows up in every user's skill list. It therefore ships
# SKILL.md.template instead, and is exempt from the SKILL.md requirement only.
TEMPLATE_DIR = "_template"
for skill_dir in sorted(path for path in SKILLS.iterdir() if path.is_dir()):
    if skill_dir.name == TEMPLATE_DIR:
        if not (skill_dir / "SKILL.md.template").is_file():
            errors.append(f"{skill_dir.relative_to(ROOT)} has no SKILL.md.template")
        if (skill_dir / "SKILL.md").is_file():
            errors.append(
                f"{skill_dir.relative_to(ROOT)} must not contain a loadable SKILL.md"
            )
        continue
    if any(path.is_file() for path in skill_dir.rglob("*")) and not (skill_dir / "SKILL.md").is_file():
        errors.append(f"{skill_dir.relative_to(ROOT)} contains files but no SKILL.md")

known_names = set(skill_names)
package_guidance = [*sorted(SKILLS.glob("*/SKILL.md")), *REFERENCE_FILES]
for path in [*package_guidance, *COMMANDS]:
    text = path.read_text(encoding="utf-8")
    for name in sorted(set(re.findall(r"\*\*(exasol(?:-[a-z0-9-]+)?)\*\*", text))):
        if name not in known_names:
            errors.append(f"{path.relative_to(ROOT)} references missing skill {name}")

for path in package_guidance:
    if "AskUserQuestion" in path.read_text(encoding="utf-8"):
        errors.append(
            f"{path.relative_to(ROOT)} depends on a host-specific user-input tool"
        )

router_text = ROUTER.read_text(encoding="utf-8")
activations = re.findall(r"Activate:\s*\*\*(exasol-[a-z0-9-]+)\*\*", router_text)
expected_activations = known_names - {"exasol"}
for name in sorted(expected_activations - set(activations)):
    errors.append(f"top-level router does not activate {name}")
for name in sorted(set(activations) - expected_activations):
    errors.append(f"top-level router activates unknown skill {name}")
for name in sorted({name for name in activations if activations.count(name) > 1}):
    errors.append(f"top-level router activates {name} more than once")

catalog_text = (SKILLS / "exasol-extension-catalog" / "SKILL.md").read_text(
    encoding="utf-8"
)
catalog_handoffs = set(
    re.findall(r"\*\*(exasol-[a-z0-9-]+)\*\*", catalog_text)
)
expected_catalog_handoffs = known_names - {"exasol", "exasol-extension-catalog"}
for name in sorted(expected_catalog_handoffs - catalog_handoffs):
    errors.append(f"extension catalog has no handoff to {name}")

for command in COMMANDS:
    metadata = frontmatter(command)
    if not metadata.get("description"):
        errors.append(f"{command.relative_to(ROOT)} has no front-matter description")
    command_text = command.read_text(encoding="utf-8")
    if "top-level **exasol** skill" not in command_text:
        errors.append(f"{command.relative_to(ROOT)} does not delegate to the shared top-level router")
    for duplicated_marker in ["Trigger phrases:", "Activate:", "Classify the task"]:
        if duplicated_marker in command_text:
            errors.append(f"{command.relative_to(ROOT)} duplicates routing marker {duplicated_marker!r}")

readme_text = README.read_text(encoding="utf-8")
for internal_marker in ["Routing Algorithm", "Trigger phrases:", "Activate:"]:
    if internal_marker in readme_text:
        errors.append(f"README contains internal routing marker {internal_marker!r}")

for workflow in WORKFLOWS:
    top_level_keys = re.findall(
        r"^([a-zA-Z_][a-zA-Z0-9_-]*):(?:\s|$)",
        workflow.read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    for key in sorted({key for key in top_level_keys if top_level_keys.count(key) > 1}):
        errors.append(
            f"{workflow.relative_to(ROOT)} has duplicate top-level key {key!r}"
        )

marketplace = load_json(ROOT / ".claude-plugin" / "marketplace.json")
plugin = load_json(ROOT / "plugins" / "exasol" / ".claude-plugin" / "plugin.json")
marketplace_version = marketplace.get("metadata", {}).get("version", "")
plugin_version = plugin.get("version", "")
if marketplace_version != plugin_version:
    errors.append(f"manifest version mismatch: marketplace={marketplace_version!r}, plugin={plugin_version!r}")
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", marketplace_version):
    errors.append(f"manifest version is not semantic x.y.z: {marketplace_version!r}")

if errors:
    print("Package consistency checks failed:", file=sys.stderr)
    print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
    sys.exit(1)

print(
    f"Checked {len(skill_names)} skills, {len(activations)} router activations, "
    f"{len(catalog_handoffs)} catalog handoffs, {len(COMMANDS)} Claude command "
    f"delegates, {len(REFERENCE_FILES)} reference files, routed references, "
    "cross-agent input guidance, README boundaries, workflow keys, "
    "and manifest versions."
)
