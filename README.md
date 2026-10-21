# Homebrew tap

Casks and formulae for Eric Andrechek's projects.

```sh
brew install --cask ericandrechek/tap/pacer
brew install ericandrechek/tap/shelp
```

| Cask | What |
|---|---|
| [`pacer`](Casks/pacer.rb) | [Pacer](https://github.com/EricAndrechek/Pacer): a menu bar tracker for Claude Code usage, cost and rate limits. It updates itself, so `brew upgrade` leaves it alone. |

| Formula | What |
|---|---|
| [`shelp`](Formula/shelp.rb) | [shelp](https://github.com/EricAndrechek/shelp): turn a task into a shell command, or explain one, with the model you have. Built from source. |

## How casks stay current

[`autobump`](.github/workflows/autobump.yml) runs every six hours, and on demand right after a project publishes a release. For each cask in [`.github/autobump.json`](.github/autobump.json) it asks the cask's `livecheck` for the newest version, and pins it only if the download proves to be ours:

- the disk image and the app inside are signed by the Developer ID team named in `autobump.json`;
- Apple notarized it, and the ticket is stapled;
- it is strictly newer than the version pinned now, so no downgrades.

The sha256 it pins is that of the exact bytes it verified. Anything else is refused and nothing is committed. No project holds a key to this repo; only this repo's own workflow token writes here.

## How formulae stay current

The same [`autobump`](.github/workflows/autobump.yml) handles each formula in `autobump.json`: `livecheck` finds the newest version, and it is pinned only if the source proves to be ours:

- the release tag is an annotated tag signed by the GPG key named in `autobump.json`, checked against that key's copy in [`.github/keys/`](.github/keys) (never one fetched from the project);
- the tarball is identical to the tree of that tag;
- it is strictly newer than the version pinned now, so no downgrades.

The sha256 it pins is that of the exact tarball it verified. Formulae are built from source, so there is no notarization step; the signature is the proof. Anything else is refused and nothing is committed.

## Adding a cask

1. Add `Casks/<name>.rb` with a `livecheck` block (for GitHub releases, `url :url` with `strategy :github_latest`).
2. Add `"<name>": { "team_id": "<Developer ID team>", "app": "<Name>.app" }` to `.github/autobump.json`.
3. Optionally, have the project ask this tap to check as soon as its release is published, so the cask follows within minutes rather than at the next six-hourly check. Copy [Pacer's `homebrew-tap.yml`](https://github.com/EricAndrechek/Pacer/blob/main/.github/workflows/homebrew-tap.yml) into the project (changing `cask=` and the workflow it follows), and give it a `HOMEBREW_TAP_TRIGGER_TOKEN` secret: a fine-grained personal access token with access to this repo only and *Actions: Read and write* only. That token can start this workflow and nothing else; it cannot write here.

## Adding a formula

1. Add `Formula/<name>.rb` with a `livecheck` block (for GitHub releases, `url :stable` with `strategy :github_latest`). Its `url` is the tag's `archive/refs/tags/v<version>.tar.gz`; until the project is public the `sha256` is a placeholder, and the first autobump run (or `brew bump-formula-pr`) replaces it.
2. Add `"<name>": { "repo": "<owner>/<repo>", "signing_key": "<full 40-digit fingerprint>" }` under `formulae` in `.github/autobump.json`. The project must publish releases as signed, annotated tags (`git tag -s`).
3. Add the key's public half, ASCII-armored, as `.github/keys/<fingerprint>.asc`.
4. Optionally, have the project ask this tap to check as soon as its release is published, as for a cask but with `-f formula=<name>` in place of `-f cask=<name>`: `gh workflow run autobump.yml -R EricAndrechek/homebrew-tap -f formula=<name>`, using the same fine-grained `HOMEBREW_TAP_TRIGGER_TOKEN` secret.
