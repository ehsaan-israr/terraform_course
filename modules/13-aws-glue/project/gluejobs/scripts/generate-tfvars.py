#!/usr/bin/env python3
# Requires: pip install pyyaml
"""
Read gluejobs/*/job.yaml|job.yml and emit per-environment Terraform variable files.

Merge rules:
  - Job-level fields are the base configuration.
  - default_arguments apply to every stage.
  - stages.<env> can override any job field and merge arguments on top.

Skip rules (job omitted from a stage):
  - skip_stages: [qa, uat] at job level
  - stages.<env>.skip: true for a single stage
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import yaml

STAGES = ("dev", "qa", "uat", "prod")


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    result = dict(base)
    for key, value in override.items():
        if key == "arguments" and key in result and isinstance(result[key], dict):
            result[key] = {**result[key], **value}
        else:
            result[key] = value
    return result


def load_job_config(job_yaml: Path) -> dict[str, Any]:
    with job_yaml.open(encoding="utf-8") as handle:
        config = yaml.safe_load(handle)

    if not isinstance(config, dict):
        raise ValueError(f"{job_yaml} must contain a YAML mapping")

    job_name = config.get("name") or job_yaml.parent.name
    config["name"] = job_name
    return config


def is_stage_skipped(config: dict[str, Any], stage: str) -> bool:
    skip_stages = config.get("skip_stages") or []
    if stage in skip_stages:
        return True

    stage_config = (config.get("stages") or {}).get(stage) or {}
    return bool(stage_config.get("skip", False))


def resolve_job_for_stage(config: dict[str, Any], stage: str) -> dict[str, Any]:
    base = {
        key: value
        for key, value in config.items()
        if key not in {"stages", "default_arguments", "skip_stages"}
    }

    default_arguments = dict(config.get("default_arguments") or {})
    stage_overrides = dict((config.get("stages") or {}).get(stage) or {})
    stage_arguments = dict(stage_overrides.pop("arguments", {}) or {})
    stage_overrides.pop("skip", None)

    resolved = deep_merge(base, stage_overrides)
    resolved["arguments"] = {**default_arguments, **stage_arguments}
    resolved["job_folder"] = config.get("job_folder", config["name"])
    return resolved


def discover_jobs(gluejobs_dir: Path) -> list[Path]:
    jobs = list(gluejobs_dir.glob("*/job.yaml")) + list(gluejobs_dir.glob("*/job.yml"))
    # Prefer job.yaml if both exist for the same folder
    by_folder: dict[Path, Path] = {}
    for path in sorted(jobs):
        folder = path.parent
        if folder not in by_folder or path.name == "job.yaml":
            by_folder[folder] = path
    return sorted(by_folder.values())


def generate_stage_jobs(gluejobs_dir: Path, stage: str) -> tuple[dict[str, Any], list[str]]:
    jobs: dict[str, Any] = {}
    skipped: list[str] = []

    for job_yaml in discover_jobs(gluejobs_dir):
        config = load_job_config(job_yaml)
        config["job_folder"] = job_yaml.parent.name

        if is_stage_skipped(config, stage):
            skipped.append(config["name"])
            continue

        resolved = resolve_job_for_stage(config, stage)
        jobs[resolved["name"]] = resolved

    return jobs, skipped


def write_tfvars(jobs: dict[str, Any], output_path: Path) -> None:
    payload = {"glue_jobs": jobs}
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def write_active_folders(jobs: dict[str, Any], output_path: Path) -> None:
    folders = sorted({job["job_folder"] for job in jobs.values()})
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(folders) + ("\n" if folders else ""), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Terraform tfvars from Glue job configs")
    parser.add_argument(
        "--gluejobs-dir",
        type=Path,
        default=Path("gluejobs"),
        help="Directory containing Glue job folders",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("gluejobs/terraform/generated"),
        help="Output directory for generated Terraform files",
    )
    parser.add_argument(
        "--stage",
        choices=STAGES,
        help="Generate only one stage (default: all stages)",
    )
    args = parser.parse_args()

    stages = [args.stage] if args.stage else list(STAGES)

    for stage in stages:
        jobs, skipped = generate_stage_jobs(args.gluejobs_dir, stage)

        if args.stage:
            generated_dir = args.output_dir
        else:
            generated_dir = args.output_dir / stage

        tfvars_path = generated_dir / "glue-jobs.auto.tfvars.json"
        active_folders_path = generated_dir / "active-job-folders.txt"

        write_tfvars(jobs, tfvars_path)
        write_active_folders(jobs, active_folders_path)

        print(f"Wrote {len(jobs)} job(s) to {tfvars_path}")
        if skipped:
            print(f"Skipped {len(skipped)} job(s) for {stage}: {', '.join(skipped)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
