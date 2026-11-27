cask "pacer" do
  version "0.9.6"
  sha256 "e6aa1a5026d19b380b1080a060fd5938e39ab1f4f60747b855c2b2dac81d2323"

  url "https://github.com/EricAndrechek/Pacer/releases/download/v#{version}/Pacer-#{version}.dmg"
  name "Pacer"
  desc "Menu bar tracker for Claude Code usage, cost and rate limits"
  homepage "https://github.com/EricAndrechek/Pacer"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :sequoia

  app "Pacer.app"
  # The `pacer` command line ships inside the app (from v0.7.4). Linked from
  # the app, so Sparkle's in-place updates keep it current.
  binary "#{appdir}/Pacer.app/Contents/Helpers/PacerCLI.app/Contents/MacOS/pacer"

  # Leaves the usage history in Pacer's App Group container: --zap removes the
  # app's settings and logs, not data that can't be rebuilt from scratch.
  zap trash: [
    "~/Library/Caches/com.ericandrechek.pacer",
    "~/Library/HTTPStorages/com.ericandrechek.pacer",
    "~/Library/Logs/Pacer",
    "~/Library/Preferences/com.ericandrechek.pacer.plist",
    "~/Library/Saved Application State/com.ericandrechek.pacer.savedState",
  ]
end
