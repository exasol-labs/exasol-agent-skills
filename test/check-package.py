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
AGENTS = ROOT / "AGENTS.md"
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
    load_references = {
        match
        for line in skill_text.splitlines()
        if "Load:" in line
        for match in re.findall(r"references/[a-zA-Z0-9._/-]+\.md", line)
    }
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

# The template directory sits next to the skills it is copied from, but it is
# not a skill itself: any directory under skills/ that holds a SKILL.md turns
# into a skill that every user of the plugin sees in their skill list. The
# template therefore ships SKILL.md.template, and only the rule that a skill
# directory must hold a SKILL.md is waived for it.
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
# The README is only checked one way round. It does not have to mention every
# skill, because it is written for users, who do not type skill names such as
# "exasol-notebook-connector-config". But if it does write a skill name in
# bold, that skill has to exist.
for path in [*package_guidance, *COMMANDS, README]:
    text = path.read_text(encoding="utf-8")
    for name in sorted(set(re.findall(r"\*\*(exasol(?:-[a-z0-9-]+)?)\*\*", text))):
        if name not in known_names:
            errors.append(f"{path.relative_to(ROOT)} references missing skill {name}")

for path in package_guidance:
    if "AskUserQuestion" in path.read_text(encoding="utf-8"):
        errors.append(
            f"{path.relative_to(ROOT)} depends on a host-specific user-input tool"
        )

# Nothing here requires the router to name every skill. The router now holds
# only the rules about which skill wins a conflict, which skill has to run
# first, and which safety rules apply to several skills at once, so most skills
# are missing from it on purpose. Whether a skill gets chosen depends on how
# well its own description is written, and this script cannot judge that. The
# other direction is still checked: the "references missing skill" scan above
# reads the router too, so a rule that names a skill which does not exist
# fails.
router_text = ROUTER.read_text(encoding="utf-8")
router_skills = set(re.findall(r"\*\*(exasol-[a-z0-9-]+)\*\*", router_text))
if "Trigger phrases:" in router_text or "Activate:" in router_text:
    errors.append(
        "top-level router reintroduces per-skill trigger lists; keep it an arbiter"
    )

catalog_text = (SKILLS / "exasol-extension-catalog" / "SKILL.md").read_text(
    encoding="utf-8"
)
catalog_handoffs = set(
    re.findall(r"\*\*(exasol-[a-z0-9-]+)\*\*", catalog_text)
)
expected_catalog_handoffs = known_names - {"exasol", "exasol-extension-catalog"}
for name in sorted(expected_catalog_handoffs - catalog_handoffs):
    errors.append(f"extension catalog has no handoff to {name}")

# AGENTS.md lists the skills the package contains, so that people reading the
# repository can see what is in it, and nothing else checks that list. Only
# that one line is read, because AGENTS.md also mentions names that look like
# skills but are not: the made-up example `Use **exasol-foo**` and the install
# command `exasol@exasol-skills`. Reading the whole file would report those as
# errors right away, and a check that reports errors that are not errors ends
# up being deleted.
agents_skill_lines = [
    line
    for line in AGENTS.read_text(encoding="utf-8").splitlines()
    if line.startswith("- `plugins/exasol/skills/*/SKILL.md`") and "Skills:" in line
]
if len(agents_skill_lines) != 1:
    errors.append(
        "AGENTS.md has no single Architecture skill-list line; expected one line "
        'starting with "- `plugins/exasol/skills/*/SKILL.md`" and containing "Skills:"'
    )
else:
    listed_skills = set(
        re.findall(
            r"`(exasol(?:-[a-z0-9-]+)?)`",
            agents_skill_lines[0].split("Skills:", 1)[1],
        )
    )
    for name in sorted(known_names - listed_skills):
        errors.append(
            f"AGENTS.md Architecture skill list does not name {name}; add it to "
            "the Skills: line"
        )
    for name in sorted(listed_skills - known_names):
        errors.append(
            f"AGENTS.md Architecture skill list names unknown skill {name}; drop "
            f"it from the Skills: line or add plugins/exasol/skills/{name}/SKILL.md"
        )

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
    f"Checked {len(skill_names)} skills, {len(router_skills)} skills named by the "
    "router's precedence rules, "
    f"{len(catalog_handoffs)} catalog handoffs, {len(COMMANDS)} Claude command "
    f"delegates, {len(REFERENCE_FILES)} reference files, routed references, "
    "cross-agent input guidance, the AGENTS.md architecture skill list, README "
    "boundaries, workflow keys, and manifest versions."
)
