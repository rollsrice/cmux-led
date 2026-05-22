cask "cmux-led" do
  version "0.1.1"
  sha256 "2e3da5dae8c98e7083aa5f2105fe1c24c75a3b763ae93bbaccfab3a6c8aad0ac"

  url "https://github.com/rollsrice/cmux-led/releases/download/v#{version}/cmux-led.zip"
  name "cmux LED"
  desc "Floating LED overlay showing cmux Claude session activity"
  homepage "https://github.com/rollsrice/cmux-led"

  depends_on macos: ">= :ventura"

  app "cmux-led.app"

  zap trash: [
    "~/Library/Preferences/com.thirdintelligence.cmux-led.plist",
  ]
end
