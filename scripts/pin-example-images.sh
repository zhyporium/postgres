#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="ghcr.io/zhyporium/postgres"

DIRS=(
  examples/18
  examples/18_pgvector
  examples/18_timescale
  examples/18_vt
)
TAGS=(
  18
  18_pgvector
  18_timescale
  18_vt
)

update_file() {
  local file="$1"
  local image_ref="$2"

  if [ ! -f "${file}" ]; then
    echo "skip missing: ${file}"
    return
  fi

  if grep -q '^POSTGRES_IMAGE=' "${file}"; then
    sed -i.bak "s|^POSTGRES_IMAGE=.*|POSTGRES_IMAGE=${image_ref}|" "${file}"
    rm -f "${file}.bak"
  else
    printf '\nPOSTGRES_IMAGE=%s\n' "${image_ref}" >> "${file}"
  fi
}

echo "Resolving image digests from ${REGISTRY}..."
echo ""

for i in "${!DIRS[@]}"; do
  dir="${DIRS[$i]}"
  tag="${TAGS[$i]}"
  digest="$(docker buildx imagetools inspect "${REGISTRY}:${tag}" --format '{{.Manifest.Digest}}')"
  image_ref="${REGISTRY}:${tag}@${digest}"

  update_file "${ROOT}/${dir}/.env.example" "${image_ref}"
  update_file "${ROOT}/${dir}/.env" "${image_ref}"

  echo "${dir}: ${image_ref}"
done

echo ""
echo "Done. Copy .env.example to .env if needed."
