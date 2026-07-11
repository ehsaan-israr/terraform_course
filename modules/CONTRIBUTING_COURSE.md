# Contributing to Course Modules

Each numbered directory is a self-contained learning module. Keep changes scoped
to the module you are improving unless a shared course convention needs to
change.

## Module structure

Use this layout for student-facing modules:

```text
modules/NN-topic-name/
  README.md
  exercises/
    README.md
  solutions/
    README.md
  project/
    versions.tf
    providers.tf
    variables.tf
    main.tf
    outputs.tf
```

Larger modules may add subdirectories under `project/`, such as child modules,
CI examples, or environment roots.

## Writing guidance

- `README.md` teaches the concepts and explains why the module matters.
- `exercises/README.md` gives hands-on tasks without giving away every answer.
- `solutions/README.md` should answer each exercise with working HCL snippets,
  expected plan behavior, and safety notes.
- `project/` should be runnable in a sandbox account and default to the lowest
  reasonable cost for the lesson.
- Prefer small, explicit examples over production-scale abstractions unless the
  module is specifically about production design.

## Terraform conventions

- Keep `terraform fmt -recursive` clean.
- Pin provider versions in `versions.tf`.
- Put user-adjustable values in `variables.tf` with descriptions and validation
  when helpful.
- Put stable, useful values in `outputs.tf`.
- Do not commit real `terraform.tfvars`, state files, plan files, credentials,
  or generated `.terraform/` directories.
- Add cost and cleanup warnings when examples create billable resources.

## Student safety

Use documentation CIDRs such as `203.0.113.0/24` in examples, call out when
values must be replaced, and remind students to destroy lab resources after
finishing.
