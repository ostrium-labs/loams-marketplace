# Loams Marketplace index

The open index behind the Loams Marketplace: listings of **agents** (any framework, any language; Mastra is the first-class path), **harnesses** (coding agents that `loams-agentd` drives, usually over ACP) and **MCP servers**, which you install into your own Loams.

- **Metadata only.** This repository holds listing manifests, never package bytes. Code stays on npm, PyPI, OCI registries and GitHub Releases, signed with provenance.
- **Signed.** On every merge, CI builds `index.json` and `revocations.json` and signs them with Sigstore keyless signing from this repository's publish workflow. Loams installs verify that signature, each artifact's integrity hash and its provenance before anything is installed.
- **Reviewed in the open.** A listing is a pull request. CI validates the manifest, checks provenance and licence, scans the package and runs the agent package conformance suite (LAPC), then posts a report.
- **Federated.** This is the official source. Anyone can run their own index with the same layout, and a Loams install can add sources pinned to their signing identities.
- **Free.** Every listing is free. There are no accounts and no install telemetry.

## Status

**Experimental.** First-party listings only (namespaces `ostrium` and `loams`) until MK1. Third-party submissions open after that, with namespace verification and the sandbox.

## Layout

    listings/<namespace>/<name>/listing.json   the current manifest (schema: schemas/listing.v1.json)
    listings/<namespace>/<name>/versions/      one file per published version
    publishers/<namespace>.json                verified publisher records
    revocations.json                           signed revocations (warn, disable)
    schemas/                                   listing schema v1

## Install a listing

From Loams Desktop or the console, open **Marketplace**. From a terminal:

    loams marketplace search <query>
    loams marketplace install <namespace>/<name>

The install screen is generated from the manifest. It shows the data, tools, network hosts, models and budget the listing asks for, and nothing is created until you confirm.

## Design

- Design 73, The Loams Agent Marketplace: https://github.com/ostrium-labs/loams/blob/dev/docs/design/73-agent-marketplace.md
- Plan MK1: https://github.com/ostrium-labs/loams/blob/dev/docs/plans/2026-10-21-mk1-agent-marketplace.md

## Licence

Apache-2.0. Each listed package keeps its own licence, which its listing declares.
