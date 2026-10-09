#!/usr/bin/env bash
set -euo pipefail

FW=/usr/libexec/ApplicationFirewall/socketfilterfw

sudo -v

echo "== Application Firewall =="
sudo "$FW" --setglobalstate on
sudo "$FW" --setstealthmode on
sudo "$FW" --setallowsigned on
sudo "$FW" --setallowsignedapp off
sudo pkill -HUP socketfilterfw || true

echo "== Homebrew =="
sudo xcodebuild -license accept 2>/dev/null || true
if command -v brew >/dev/null; then
  brew analytics off && echo "brew analytics: off"
fi

echo "== User defaults =="
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults write com.apple.CrashReporter DialogType none
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
chflags nohidden ~/Library

echo
echo "== Status =="
for f in --getglobalstate --getstealthmode --getallowsigned --getblockall; do "$FW" "$f"; done
fdesetup status
csrutil status
spctl --status
echo "Done. Restart the terminal to pick up fish environment variables."
