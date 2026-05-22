cask "cmux-led" do
  version "0.1.2"
  sha256 "48f2fb4e2b87881fa6752eaa98e64319a59562470b812f17f5b3cc7c43bcaa5e"

  url "https://github.com/rollsrice/homebrew-cmux-led/releases/download/v#{version}/cmux-led.zip"
  name "cmux LED"
  desc "Floating LED overlay showing cmux Claude session activity"
  homepage "https://github.com/rollsrice/homebrew-cmux-led"

  depends_on macos: ">= :ventura"

  app "cmux-led.app"

  postflight do
    require "json"
    require "fileutils"

    intro = <<~MSG.chomp
      cmux-led needs cmux to allow external socket control. This edits ~/.config/cmux/cmux.json (a timestamped backup is written next to it).

      To apply the change, cmux must be quit and reopened — any running terminal panes will close.

      Enable now?
    MSG

    consent = system_command(
      "/usr/bin/osascript",
      args: [
        "-e",
        %(display dialog "#{intro.gsub('"', '\\"')}" buttons {"Skip","Enable"} default button "Enable" with title "cmux-led setup"),
      ],
      must_succeed: false,
    )
    next unless consent.success? && consent.stdout.include?("Enable")

    cfg_dir = File.expand_path("~/.config/cmux")
    cfg = "#{cfg_dir}/cmux.json"
    FileUtils.mkdir_p(cfg_dir)

    src = File.exist?(cfg) ? File.read(cfg) : "{}"
    if File.exist?(cfg)
      FileUtils.cp(cfg, "#{cfg}.bak.#{Time.now.strftime('%Y%m%d-%H%M%S')}")
    end

    # JSONC strip: line/block comments outside strings, then trailing commas
    out = +""
    i = 0
    n = src.length
    in_str = false
    esc = false
    while i < n
      c = src[i]
      if in_str
        out << c
        if esc
          esc = false
        elsif c == "\\"
          esc = true
        elsif c == '"'
          in_str = false
        end
        i += 1
        next
      end
      if c == '"'
        in_str = true
        out << c
        i += 1
        next
      end
      if c == "/" && src[i + 1] == "/"
        i += 1 while i < n && src[i] != "\n"
        next
      end
      if c == "/" && src[i + 1] == "*"
        i += 2
        i += 1 while i + 1 < n && !(src[i] == "*" && src[i + 1] == "/")
        i += 2
        next
      end
      out << c
      i += 1
    end
    out.gsub!(/,(\s*[}\]])/, '\1')

    data = begin
      JSON.parse(out)
    rescue StandardError
      {}
    end
    data["automation"] ||= {}
    data["automation"]["socketControlMode"] = "allowAll"

    tmp = "#{cfg}.tmp.#{Process.pid}"
    File.open(tmp, "w", 0o600) { |f| f.write(JSON.pretty_generate(data) + "\n") }
    File.rename(tmp, cfg)

    restart_prompt = <<~MSG.chomp
      cmux config updated. Restart cmux now to apply?

      Running terminal panes will close. You can also restart later.
    MSG

    restart = system_command(
      "/usr/bin/osascript",
      args: [
        "-e",
        %(display dialog "#{restart_prompt.gsub('"', '\\"')}" buttons {"Later","Restart cmux now"} default button "Later" with title "cmux-led setup"),
      ],
      must_succeed: false,
    )
    if restart.success? && restart.stdout.include?("Restart cmux now")
      system_command("/usr/bin/osascript", args: ["-e", 'tell application "cmux" to quit'], must_succeed: false)
      sleep 2
      system_command("/usr/bin/open", args: ["-a", "cmux"], must_succeed: false)
    end
  end

  zap trash: [
    "~/Library/Preferences/com.thirdintelligence.cmux-led.plist",
  ]
end
