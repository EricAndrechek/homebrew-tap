# Homebrew tap

Casks and formulae for Eric Andrechek's projects.

```sh
brew install --cask ericandrechek/tap/pacer
```

| Cask | What |
|---|---|
| [`pacer`](Casks/pacer.rb) | [Pacer](https://github.com/EricAndrechek/Pacer): a menu bar tracker for Claude Code usage, cost and rate limits. It updates itself, so `brew upgrade` leaves it alone. |

## How casks stay current

[`autobump`](.github/workflows/autobump.yml) runs every six hours, and on demand right after a project publishes a release. For each cask in [`.github/autobump.json`](.github/autobump.json) it asks the cask's `livecheck` for the newest version, and pins it only if the download proves to be ours:

- the disk image and the app inside are signed by the Developer ID team named in `autobump.json`;
- Apple notarized it, and the ticket is stapled;
- it is strictly newer than the version pinned now, so no downgrades.

The sha256 it pins is that of the exact bytes it verified. Anything else is refused and nothing is committed. No project holds a key to this repo; only this repo's own workflow token writes here.

## Adding a cask

1. Add `Casks/<name>.rb` with a `livecheck` block (for GitHub releases, `url :url` with `strategy :github_latest`).
2. Add `"<name>": { "team_id": "<Developer ID team>", "app": "<Name>.app" }` to `.github/autobump.json`.
3. Optionally, have the project ask this tap to check as soon as its release is published, so the cask follows within minutes rather than at the next six-hourly check. Copy [Pacer's `homebrew-tap.yml`](https://github.com/EricAndrechek/Pacer/blob/main/.github/workflows/homebrew-tap.yml) into the project (changing `cask=` and the workflow it follows), and give it a `HOMEBREW_TAP_TRIGGER_TOKEN` secret: a fine-grained personal access token with access to this repo only and *Actions: Read and write* only. That token can start this workflow and nothing else; it cannot write here.
