#!/usr/bin/env python3
"""
Detect which Glue jobs changed between two git refs.

Important:
  Terraform tfvars must still include ALL jobs for the stage.
  Selective mode only limits `terraform -target` and S3 script uploads.
  Filtering tfvars to changed jobs would destroy unchanged jobs.

Outputs (GitHub Actions):
  mode=full|selective
  jobs=folder-a,folder-b
  reason=...
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


FULL_PATH_PREFIXES = (
    "gluejobs/terraform/",
    "gluejobs/scripts/",
    ".github/workflows/glue-",
    ".github/workflows/reusable-glue-",
)

JOB_CONFIG_NAMES = {"job.yaml", "job.yml"}


def run_git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def changed_paths(base_ref: str, head_ref: str) -> list[tuple[str, str]]:
    output = run_git("diff", "--name-status", f"{base_ref}...{head_ref}")
    rows: list[tuple[str, str]] = []
    for line in output.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status = parts[0]
        if status.startswith("R") and len(parts) >= 3:
            rows.append((status, parts[1]))
            rows.append((status, parts[2]))
        elif len(parts) >= 2:
            rows.append((status, parts[1]))
    return rows


def classify(paths: list[tuple[str, str]], gluejobs_dir: Path) -> tuple[str, list[str], str]:
    changed_jobs: set[str] = set()
    deleted_job = False

    for status, path in paths:
        normalized = path.replace("\\", "/")

        if any(
            normalized.startswith(prefix) or normalized == prefix.rstrip("/")
            for prefix in FULL_PATH_PREFIXES
        ):
            return "full", [], f"shared glue path changed: {normalized}"

        if not normalized.startswith("gluejobs/"):
            continue

        parts = normalized.split("/")
        if len(parts) < 2:
            continue

        job_folder = parts[1]
        if job_folder == "terraform":
            return "full", [], f"terraform stack changed: {normalized}"

        relative = parts[2:] if len(parts) > 2 else []
        is_job_config = bool(relative) and relative[0] in JOB_CONFIG_NAMES
        is_job_script = bool(relative) and relative[0] == "scripts"
        is_job_file = is_job_config or is_job_script or len(relative) > 0

        if status.startswith("D") and (is_job_config or not (gluejobs_dir / job_folder).is_dir()):
            deleted_job = True
            changed_jobs.add(job_folder)
            continue

        if is_job_file:
            changed_jobs.add(job_folder)

    if deleted_job:
        return "full", sorted(changed_jobs), "job deleted; full plan/apply required to destroy"

    if not changed_jobs:
        return "full", [], "no per-job changes detected; defaulting to full"

    return "selective", sorted(changed_jobs), "per-job changes only"


def write_output(path: Path | None, mode: str, jobs: list[str], reason: str) -> None:
    text = "\n".join(
        [
            f"mode={mode}",
            f"jobs={','.join(jobs)}",
            f"reason={reason}",
        ]
    ) + "\n"
    if path:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as handle:
            handle.write(text)
    print(text, end="")


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect changed Glue jobs for selective CI")
    parser.add_argument("--base-ref", required=True, help="Git base ref (PR base or push before SHA)")
    parser.add_argument("--head-ref", default="HEAD", help="Git head ref")
    parser.add_argument("--gluejobs-dir", type=Path, default=Path("gluejobs"))
    parser.add_argument("--force-all", action="store_true", help="Force full mode")
    parser.add_argument("--github-output", type=Path, help="Append outputs for GitHub Actions")
    args = parser.parse_args()

    if args.force_all:
        write_output(args.github_output, "full", [], "force_all requested")
        return 0

    try:
        paths = changed_paths(args.base_ref, args.head_ref)
    except subprocess.CalledProcessError as exc:
        print(exc.stderr, file=sys.stderr)
        write_output(args.github_output, "full", [], "git diff failed; defaulting to full")
        return 0

    mode, jobs, reason = classify(paths, args.gluejobs_dir)
    write_output(args.github_output, mode, jobs, reason)
    return 0


if __name__ == "__main__":
    sys.exit(main())
