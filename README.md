# nim-repo

GitHub template repository for Nim packages using Atlas for dependency
management and GitHub Actions for CI.

## Use This Template

1. Create a new repository with GitHub's "Use this template" button.
2. Clone the new repository locally.
3. Pick the Nim package name you want to publish, using letters, numbers, and
   underscores.
4. Run:

```sh
./scripts/rename_template.sh your_package_name
```

That updates the starter package/module/test filenames and rewrites the
remaining `nim_repo` / `nim-repo` references in the template files.

## Setup

```sh
atlas install
```

Atlas writes dependency paths to `nim.cfg` and installs dependencies under
`deps/`. Those files are intentionally ignored.

## Test

Run the full test suite:

```sh
nim test
```

Run a single test:

```sh
nim r tests/tyour_package_name.nim
```

## Layout

- `src/your_package_name.nim`: package module after renaming.
- `tests/tyour_package_name.nim`: unit tests after renaming.
- `config.nims`: shared Nim switches and the `nim test` task.
- `.github/workflows/ci.yml`: GitHub Actions CI.
- `scripts/rename_template.sh`: one-shot template bootstrap rename.
# nim-repo
