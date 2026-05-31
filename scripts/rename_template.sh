#!/usr/bin/env sh

set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <package_name>" >&2
  exit 1
fi

old_name="nim_repo"
new_name="$1"
old_repo_name="nim-repo"
new_repo_name=$(printf '%s' "$new_name" | tr '_' '-')
old_test="tests/tnim_repo.nim"
new_test="tests/t${new_name}.nim"

case "$new_name" in
  *[!A-Za-z0-9_]* | "")
    echo "package_name must contain only letters, numbers, and underscores" >&2
    exit 1
    ;;
esac

for path in "src/${old_name}.nim" "${old_name}.nimble" "${old_test}" README.md; do
  if [ ! -f "$path" ]; then
    echo "expected template file not found: $path" >&2
    exit 1
  fi
done

if [ -e "src/${new_name}.nim" ] || [ -e "${new_name}.nimble" ] || [ -e "${new_test}" ]; then
  echo "target files already exist for package name: ${new_name}" >&2
  exit 1
fi

mv "src/${old_name}.nim" "src/${new_name}.nim"
mv "${old_name}.nimble" "${new_name}.nimble"
mv "${old_test}" "${new_test}"

perl -0pi -e "s/\\bnim_repo\\b/${new_name}/g; s/\\bnim-repo\\b/${new_repo_name}/g" \
  README.md \
  "src/${new_name}.nim" \
  "${new_name}.nimble" \
  "${new_test}" \
  AGENTS.md

rm -- "$0"

echo "Renamed template package to '${new_name}'."
