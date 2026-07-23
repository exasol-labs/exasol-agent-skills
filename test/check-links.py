#!/usr/bin/env python3
"""Check links in tracked Markdown files.

The checker validates:
- local relative links point to files or directories in the repository
- local heading anchors exist when present
- HTTP(S) links do not return an error status

It intentionally accepts 403 and 429 for external links because some services block
or rate-limit automated CI requests even when the link is valid for users.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

MARKDOWN_LINK_RE = re.compile(
    r"!?\[[^]]*]"  # link text
    r"\(([^)\s]+)(?:\s+\"[^\"]*\")?\)",
    re.VERBOSE,
)
BARE_URL_RE = re.compile(r"https?://[^\s<>)\]\"']+")
HEADING_RE = re.compile(r"^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$")
HTML_ANCHOR_RE = re.compile(r"<(?:a|[^>]+\s+id=)[^>]*(?:id|name)=[\"']([^\"']+)[\"'][^>]*>", re.IGNORECASE)
TRAILING_PUNCTUATION = ".,;:!?)]}>'\"”’"
ACCEPTED_EXTERNAL_STATUSES = {403, 429}
USER_AGENT = "exasol-agent-skills-link-check/1.0"
IGNORED_EXTERNAL_PATTERNS = (
    "https://my-bucket.",
    "https://github.com/some/",
    "http://w",
)


def tracked_markdown_files(repo: Path) -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "*.md"],
        cwd=repo,
        check=True,
        text=True,
        capture_output=True,
    )
    return [repo / line for line in result.stdout.splitlines() if line]


def slugify_heading(heading: str) -> str:
    heading = re.sub(r"<[^>]+>", "", heading)
    heading = re.sub(r"[`*_~]", "", heading)
    heading = heading.strip().lower()
    heading = re.sub(r"[^a-z0-9\s-]", "", heading)
    heading = re.sub(r"\s+", "-", heading)
    heading = re.sub(r"-+", "-", heading)
    return heading.strip("-")


def anchors_for(path: Path) -> set[str]:
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(errors="ignore")
    for line in text.splitlines():
        match = HEADING_RE.match(line)
        if match:
            base = slugify_heading(match.group(1))
            if base:
                count = counts.get(base, 0)
                counts[base] = count + 1
                anchors.add(base if count == 0 else f"{base}-{count}")
        for anchor in HTML_ANCHOR_RE.findall(line):
            anchors.add(anchor)
    return anchors


def normalize_url(raw: str) -> str:
    raw = raw.strip()
    while raw and raw[-1] in TRAILING_PUNCTUATION:
        raw = raw[:-1]
    return raw


def links_in_file(path: Path) -> list[tuple[int, str]]:
    links: list[tuple[int, str]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
        seen_on_line: set[str] = set()
        for match in MARKDOWN_LINK_RE.finditer(line):
            url = normalize_url(match.group(1))
            if url and url not in seen_on_line:
                links.append((line_number, url))
                seen_on_line.add(url)
        for match in BARE_URL_RE.finditer(line):
            url = normalize_url(match.group(0))
            if url and url not in seen_on_line:
                links.append((line_number, url))
                seen_on_line.add(url)
    return links


def check_external(url: str, timeout: float) -> str | None:
    if any(url.startswith(pattern) for pattern in IGNORED_EXTERNAL_PATTERNS):
        return None
    headers = {"User-Agent": USER_AGENT}
    for method in ("HEAD", "GET"):
        request = urllib.request.Request(url, method=method, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                status = response.getcode()
                if 200 <= status < 400 or status in ACCEPTED_EXTERNAL_STATUSES:
                    return None
                return f"HTTP {status}"
        except urllib.error.HTTPError as error:
            if method == "HEAD":
                continue
            if error.code in ACCEPTED_EXTERNAL_STATUSES:
                return None
            return f"HTTP {error.code}"
        except Exception as error:  # noqa: BLE001 - diagnostics should include the original failure text.
            if method == "HEAD":
                continue
            return str(error)
    return "unreachable"


def check_local(repo: Path, source: Path, url: str, anchor_cache: dict[Path, set[str]]) -> str | None:
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme in {"mailto", "tel"}:
        return None
    if parsed.scheme or parsed.netloc:
        return None
    if url.startswith("#"):
        target = source
        fragment = parsed.fragment
    else:
        raw_path = urllib.parse.unquote(parsed.path)
        target = (source.parent / raw_path).resolve()
        fragment = parsed.fragment
    try:
        target.relative_to(repo.resolve())
    except ValueError:
        return f"local link escapes repository: {url}"
    if not target.exists():
        return f"missing local target: {url}"
    if fragment and target.is_file():
        anchors = anchor_cache.setdefault(target, anchors_for(target))
        decoded_fragment = urllib.parse.unquote(fragment)
        if decoded_fragment not in anchors:
            return f"missing anchor #{fragment} in {target.relative_to(repo)}"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Check links in tracked Markdown files.")
    parser.add_argument("--timeout", type=float, default=15.0, help="External link timeout in seconds.")
    parser.add_argument("--skip-external", action="store_true", help="Only check local links and anchors.")
    args = parser.parse_args()

    repo = Path.cwd().resolve()
    files = tracked_markdown_files(repo)
    failures: list[str] = []
    external_cache: dict[str, str | None] = {}
    anchor_cache: dict[Path, set[str]] = {}

    for path in files:
        for line_number, url in links_in_file(path):
            parsed = urllib.parse.urlsplit(url)
            if parsed.scheme in {"http", "https"}:
                if not args.skip_external:
                    error = external_cache.setdefault(url, check_external(url, args.timeout))
                    if error:
                        failures.append(f"{path.relative_to(repo)}:{line_number}: {url} -> {error}")
            else:
                error = check_local(repo, path, url, anchor_cache)
                if error:
                    failures.append(f"{path.relative_to(repo)}:{line_number}: {error}")

    if failures:
        print("Link check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"Checked links in {len(files)} Markdown files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
