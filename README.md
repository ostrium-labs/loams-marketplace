# The Seed Exchange: the Loams Marketplace index

This repository is the official index of the Loams Marketplace, the Seed Exchange (design [§73](https://github.com/ostrium-labs/loams/blob/dev/docs/design/73-agent-marketplace.md), plan [MK1](https://github.com/ostrium-labs/loams/blob/dev/docs/plans/2026-10-21-mk1-agent-marketplace.md)). Loams Desktop and `loams-agentd` read it to list agents, harnesses and MCP servers, and to install them into ground you own.

**Status: experimental, first-party only.** MK0 accepts listings in the `ostrium` and `loams` namespaces. Third-party listings open in MK1, after Loams' sandbox lands.

## What is here

- **Metadata only.** A listing points at code on npm, PyPI, OCI registries or GitHub Releases. The code never lives here, and neither do package bytes.
- **Signed.** On every push to `main`, `publish.yml` builds `index.json` and `revocations.json`. It signs both with Sigstore keyless signing, as this repository's publish workflow on `main`, and publishes them to GitHub Pages. agentd refuses an index whose signature or signing identity does not match:

  ```
  identity  https://github.com/ostrium-labs/loams-marketplace/.github/workflows/publish.yml@refs/heads/main
  issuer    https://token.actions.githubusercontent.com
  ```
- **No accounts, no telemetry.** Nothing here records who installs what.

## Layout

```
listings/<namespace>/<name>/versions/<version>/listing.json   one listing version (schema listing/v1)
listings/<namespace>/<name>/versions/<version>/yanked.json    {"reason": "..."}: no new installs
listings/<namespace>/<name>/versions/<version>/provenance/    the provenance bundles CI verified
revocations.json                                              warn or disable installed versions
```

The schemas live in the Loams repository under [`schemas/marketplace`](https://github.com/ostrium-labs/loams/tree/dev/schemas/marketplace). The tooling is `loams-listing` ([`agents/loams-listing`](https://github.com/ostrium-labs/loams/tree/dev/agents/loams-listing)), pinned by commit in [`.github/loams-ref`](.github/loams-ref).

## Submitting a listing

A submission is a pull request that adds `listings/<namespace>/<name>/versions/<version>/listing.json`. For an npm package, generate the file with `loams-listing from-package <dir> --tarball <file>`. `validate.yml` then:

1. lints the listing against the schema and the semantic rules (`loams-listing rules`);
2. refuses namespaces other than `ostrium` and `loams` (MK0);
3. resolves the artifact, checks its bytes against the listing's integrity, and verifies its Sigstore provenance. The provenance must name the listing's source repository, both in the signed statement and in the signing certificate;
4. posts a report on the pull request.

The Loams Agent Package Conformance run (LAPC Core) joins this check when its runner ships (MK1 Task 8). It does not run yet.

## Licence

Apache-2.0. Each listed package keeps its own licence, shown on its listing.
