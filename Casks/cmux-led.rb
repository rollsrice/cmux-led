cask "cmux-led" do
  version "0.1.6"
  sha256 "bc6838a101fa8292ab98e3cf4d319af3c7ba09e25a833216900506eab8d56a49"

  url "https://github.com/rollsrice/homebrew-cmux-led/releases/download/v#{version}/cmux-led.zip"
  name "cmux LED"
  desc "Floating LED overlay showing cmux Claude session activity"
  homepage "https://github.com/rollsrice/homebrew-cmux-led"

  depends_on macos: ">= :ventura"

  app "cmux-led.app"

  postflight do
    require "json"
    require "fileutils"

    system_command(
      "/usr/bin/xattr",
      args: ["-dr", "com.apple.quarantine", "#{appdir}/cmux-led.app"],
      must_succeed: false,
    )

    cmux_bin = "/Applications/cmux.app/Contents/Resources/bin/cmux"

    socket_ok = lambda do
      next false unless File.executable?(cmux_bin)
      r = system_command(cmux_bin, args: ["ping"], must_succeed: false)
      r.success? && r.stdout.upcase.include?("PONG")
    end

    # Fast path: socket already accepting external connections — nothing to do.
    next if socket_ok.call

    cfg_dir = File.expand_path("~/.config/cmux")
    cfg = "#{cfg_dir}/cmux.json"

    # Parse current config (if any) to decide which dialogs to show.
    strip_jsonc = lambda do |src|
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
      out.gsub(/,(\s*[}\]])/, '\1')
    end

    current = {}
    if File.exist?(cfg)
      begin
        current = JSON.parse(strip_jsonc.call(File.read(cfg)))
      rescue StandardError
        current = {}
      end
    end
    already_allow = current.dig("automation", "socketControlMode") == "allowAll"

    if already_allow
      # Config is correct but cmux isn't running with it. Just prompt for restart.
      prompt = "cmux-led is installed. cmux needs to be restarted to apply its existing socket-control config.\n\nRestart cmux now? Running terminal panes will close."
      r = system_command(
        "/usr/bin/osascript",
        args: ["-e", %(display dialog "#{prompt.gsub('"', '\\"')}" buttons {"Later","Restart cmux now"} default button "Later" with title "cmux-led setup")],
        must_succeed: false,
      )
      if r.success? && r.stdout.include?("Restart cmux now")
        system_command("/usr/bin/osascript", args: ["-e", 'tell application "cmux" to quit'], must_succeed: false)
        sleep 2
        system_command("/usr/bin/open", args: ["-a", "cmux"], must_succeed: false)
      end
      next
    end

    # Need to edit the config first.
    intro = "cmux-led needs cmux to allow external socket control. This edits ~/.config/cmux/cmux.json (a timestamped backup is written next to it).\n\nTo apply the change, cmux must be quit and reopened — any running terminal panes will close.\n\nEnable now?"

    consent = system_command(
      "/usr/bin/osascript",
      args: ["-e", %(display dialog "#{intro.gsub('"', '\\"')}" buttons {"Skip","Enable"} default button "Enable" with title "cmux-led setup")],
      must_succeed: false,
    )
    next unless consent.success? && consent.stdout.include?("Enable")

    FileUtils.mkdir_p(cfg_dir)
    if File.exist?(cfg)
      FileUtils.cp(cfg, "#{cfg}.bak.#{Time.now.strftime('%Y%m%d-%H%M%S')}")
    end

    data = current
    data["automation"] ||= {}
    data["automation"]["socketControlMode"] = "allowAll"
    tmp = "#{cfg}.tmp.#{Process.pid}"
    File.open(tmp, "w", 0o600) { |f| f.write(JSON.pretty_generate(data) + "\n") }
    File.rename(tmp, cfg)

    restart_prompt = "cmux config updated. Restart cmux now to apply?\n\nRunning terminal panes will close. You can also restart later."
    restart = system_command(
      "/usr/bin/osascript",
      args: ["-e", %(display dialog "#{restart_prompt.gsub('"', '\\"')}" buttons {"Later","Restart cmux now"} default button "Later" with title "cmux-led setup")],
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
