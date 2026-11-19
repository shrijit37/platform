#!/usr/bin/env bash
# Idempotently install the caller workflow into an app repo and print the
# exact `gh secret set` commands needed. Never prints secret values.
set -euo pipefail

usage() {
  echo "Usage: $0 <repo-path> <app-name> [kind]" >&2
  echo "  kind: vercel | worker | container | supabase  (default: container)" >&2
}

[ $# -ge 2 ] || { usage; exit 2; }
REPO_PATH="$1"
APP_NAME="$2"
APP_KIND="${3:-container}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
EXAMPLE="$PLATFORM_ROOT/.github/workflows/caller-example.yml"
TARGET="$REPO_PATH/.github/workflows/deploy.yml"
SECRETS_FILE="${HOME}/.config/platform/secrets.env"

case "$APP_KIND" in
  vercel|worker|container|supabase) ;;
  *) echo "Unknown kind: $APP_KIND" >&2; usage; exit 2 ;;
esac
[ -d "$REPO_PATH" ] || { echo "Not a directory: $REPO_PATH" >&2; exit 1; }
[ -f "$EXAMPLE" ] || { echo "Missing example: $EXAMPLE" >&2; exit 1; }

mkdir -p "$REPO_PATH/.github/workflows"
RENDERED="$(sed -e "s/__APP_NAME__/${APP_NAME}/g" -e "s/__APP_KIND__/${APP_KIND}/g" "$EXAMPLE")"

if [ -e "$TARGET" ]; then
  if [ "$(cat "$TARGET")" = "$RENDERED" ]; then
    echo "Already up to date: $TARGET"
  else
    echo "Skipped (existing file differs; refusing to overwrite): $TARGET" >&2
  fi
else
  printf '%s\n' "$RENDERED" > "$TARGET"
  echo "Wrote: $TARGET"
fi

SECRET_NAMES=(
  SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_REF SUPABASE_DB_PASSWORD
  CLERK_SECRET_KEY CLERK_PUBLISHABLE_KEY
  CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID
  COOLIFY_WEBHOOK COOLIFY_TOKEN DOTENV_PRIVATE_KEY_PRODUCTION
)

echo
echo "Run these from $REPO_PATH (values are never echoed):"
if [ -f "$SECRETS_FILE" ]; then
  printf '  set -a; . "%s"; set +a\n' "$SECRETS_FILE"
  for s in "${SECRET_NAMES[@]}"; do
    printf '  gh secret set %s --body "$%s"\n' "$s" "$s"
  done
else
  echo "  # $SECRETS_FILE not found; gh will prompt securely for each value."
  for s in "${SECRET_NAMES[@]}"; do
    printf '  gh secret set %s\n' "$s"
  done
fi
echo "  # Optional, only if not using Vercel native Git integration:"
echo '  gh secret set VERCEL_TOKEN'
