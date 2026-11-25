cask "pacer" do
  version "0.9.4"
  sha256 "f8bbad8e4d7a7f9dd603fafc48703296f67d8e9b1f435bc8aa8f890327972f92"

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
