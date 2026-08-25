#!/usr/bin/env bash
set -euo pipefail

tag=${1:?usage: fetch-release.sh <vX.Y.Z> [output-dir]}
output_dir=${2:-assets}

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
  echo "invalid release tag: $tag" >&2
  exit 1
fi
if [[ -z "$output_dir" || "$output_dir" == "/" || "$output_dir" == "." ]]; then
  echo "unsafe output directory: $output_dir" >&2
  exit 1
fi

release_url="https://github.com/mmwx-group/mmwx-agent/releases/download/${tag}"
rm -rf -- "$output_dir"
mkdir -p -- "$output_dir"

curl_args=(--fail --silent --show-error --location --retry 3)
curl "${curl_args[@]}" -o "$output_dir/checksums.txt" "$release_url/checksums.txt"

files=()
for arch in amd64 arm64; do
  binary="mmw-agent-linux-${arch}"
  manifest="${binary}.manifest"
  curl "${curl_args[@]}" -o "$output_dir/$binary" "$release_url/$binary"
  curl "${curl_args[@]}" -o "$output_dir/$manifest" "$release_url/$manifest"
  chmod 0755 "$output_dir/$binary"
  chmod 0644 "$output_dir/$manifest"
  files+=("$binary" "$manifest")
done

(
  cd "$output_dir"
  for file in "${files[@]}"; do
    grep -E "^[0-9a-f]{64}  ${file}$" checksums.txt
  done | sha256sum --check --strict -
)

python3 - "$tag" "$output_dir" <<'PY'
import base64
import hashlib
import json
import pathlib
import sys

tag = sys.argv[1]
root = pathlib.Path(sys.argv[2])

for arch in ("amd64", "arm64"):
    binary = root / f"mmw-agent-linux-{arch}"
    manifest_path = root / f"mmw-agent-linux-{arch}.manifest"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    encoded = manifest["payload"]
    padding = "=" * ((4 - len(encoded) % 4) % 4)
    payload = json.loads(base64.urlsafe_b64decode(encoded + padding))
    digest = hashlib.sha256(binary.read_bytes()).hexdigest()

    assert payload["role"] == "agent", payload
    assert payload["release"] == tag, payload
    assert payload["goos"] == "linux", payload
    assert payload["goarch"] == arch, payload
    assert payload["executable_sha256"] == digest, (payload, digest)
    print(f"verified {tag} linux/{arch} {digest}")
PY
