#!/usr/bin/env bash
# The workflows' own tests (plan MK1 Task 3): good fixtures pass, bad ones fail,
# the index build is deterministic, published versions are immutable, and an
# unsigned or wrongly signed index never publishes (unsigned_publish_fails).
#
#   LOAMS_LISTING=<path to loams-listing.mjs> tests/self-test.sh
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cli="${LOAMS_LISTING:?set LOAMS_LISTING (scripts/setup-cli.sh prints it)}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
pass() { echo "self-test $1: ok"; }
fail() { echo "::error::self-test $1: $2"; failures=$((failures + 1)); }
expect_ok() { local name="$1"; shift; if "$@" >"$work/out" 2>&1; then pass "$name"; else cat "$work/out"; fail "$name" "expected success"; fi; }
expect_fail() { local name="$1" pattern="$2"; shift 2; if "$@" >"$work/out" 2>&1; then cat "$work/out"; fail "$name" "expected failure"; elif grep -Eq "$pattern" "$work/out"; then pass "$name"; else cat "$work/out"; fail "$name" "failed without '$pattern'"; fi; }

fx="$root/tests/fixtures"
expect_ok good_listings_lint node "$cli" lint --first-party-only $(find "$fx/good/listings" -name listing.json | sort)
expect_ok good_index_builds node "$cli" index build "$fx/good" --first-party-only --out "$work/a"
expect_fail third_party_refused 'namespace-first-party' node "$cli" index build "$fx/bad-namespace" --first-party-only --out "$work/x"
expect_fail paid_listing_refused '\[schema\]' node "$cli" index build "$fx/bad-schema" --first-party-only --out "$work/x"

node "$cli" index build "$fx/good" --first-party-only --out "$work/b" >/dev/null
if cmp -s "$work/a/index.json" "$work/b/index.json" && cmp -s "$work/a/revocations.json" "$work/b/revocations.json"; then
  pass index_build_is_deterministic
else
  fail index_build_is_deterministic "two builds of the same tree differ"
fi

expect_fail unsigned_publish_fails 'not signed' "$root/scripts/check-signed.sh" "$work/a"
echo '{"mediaType":"application/vnd.dev.sigstore.bundle.v0.3+json"}' > "$work/a/index.json.sigstore.json"
echo '{"mediaType":"application/vnd.dev.sigstore.bundle.v0.3+json"}' > "$work/a/revocations.json.sigstore.json"
expect_fail malformed_bundle_publish_fails '.' "$root/scripts/check-signed.sh" "$work/a"

# Real signatures: sign the built index keylessly as this workflow, then the
# check passes for this workflow's identity and fails for the publish
# workflow's, which is the identity agentd pins. Needs an OIDC token, so it
# runs in self-test.yml (SELF_TEST_SIGN=1) and is skipped elsewhere.
if [ "${SELF_TEST_SIGN:-}" = "1" ] && [ -n "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ]; then
  for file in index.json revocations.json; do
    cosign sign-blob --yes --bundle "$work/b/$file.sigstore.json" "$work/b/$file" >/dev/null 2>&1
  done
  self_identity="https://github.com/${GITHUB_WORKFLOW_REF:?}"
  expect_ok signed_by_the_expected_identity env LOAMS_INDEX_IDENTITY="$self_identity" "$root/scripts/check-signed.sh" "$work/b"
  expect_fail wrong_signer_publish_fails 'none of the expected identities' "$root/scripts/check-signed.sh" "$work/b"
    printf ' ' >> "$work/b/index.json"
  expect_fail tampered_index_publish_fails 'error|failed|invalid' env LOAMS_INDEX_IDENTITY="$self_identity" "$root/scripts/check-signed.sh" "$work/b"
else
  echo "self-test real-signature cases: skipped (no OIDC token)"
fi

repo="$work/repo"
git init -q "$repo"
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m base
mkdir -p "$repo/listings/ostrium/x/versions/1.0.0"
echo '{}' > "$repo/listings/ostrium/x/versions/1.0.0/listing.json"
git -C "$repo" add -A && git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q -m add
base="$(git -C "$repo" rev-parse HEAD~1)"
if [ "$(cd "$repo" && "$root/scripts/changed-listings.sh" "$base")" = "listings/ostrium/x/versions/1.0.0/listing.json" ]; then
  pass added_version_listed
else
  fail added_version_listed "the added listing was not reported"
fi
echo '{"changed":true}' > "$repo/listings/ostrium/x/versions/1.0.0/listing.json"
git -C "$repo" add -A && git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q -m edit
expect_fail published_version_immutable 'immutable' bash -c "cd '$repo' && '$root/scripts/changed-listings.sh' HEAD~1"

if [ "$failures" -gt 0 ]; then
  echo "$failures self-test(s) failed"
  exit 1
fi
echo "all self-tests passed"
