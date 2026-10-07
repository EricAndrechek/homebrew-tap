cask "pacer" do
  version "0.7.2"
  sha256 "562f92382c59c0d50ee2664647fcb38a46274e2765778f82e6cdf5fb0cf9af92"

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
