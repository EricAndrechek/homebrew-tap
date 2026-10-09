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
3. Optionally, have the project's release tooling run `gh workflow run autobump.yml -R EricAndrechek/homebrew-tap` once its release is published, so the cask follows within minutes rather than at the next six-hourly check.
