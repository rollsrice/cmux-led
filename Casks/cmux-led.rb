cask "cmux-led" do
  version "0.1.0"
  sha256 "d607a7d7ba64964212efffc436e13d5020c41bc7c3447bdf18d25f39dc05871c"

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
