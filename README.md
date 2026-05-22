# cmux-led

Tiny floating macOS overlay showing one LED per tab in your current [cmux](https://cmux.com) workspace. Green = idle, red = Claude is working. Click an LED to focus that tab.

## Install

```bash
brew tap rollsrice/cmux-led
brew install --cask cmux-led
```

First launch: right-click → Open (ad-hoc signed; Gatekeeper warns once).

## One-time cmux setup

cmux-led talks to cmux over its Unix socket. By default cmux only accepts connections from processes it spawned. Flip it once:

```bash
./setup-cmux.sh
osascript -e 'tell application "cmux" to quit' && sleep 1 && open -a cmux
```

The script backs up `~/.config/cmux/cmux.json`, sets `automation.socketControlMode = "allowAll"`, then you restart cmux. After that any local process can drive cmux — including cmux-led.

> **Security note**: `allowAll` removes cmux's default restriction that only cmux-spawned processes can use its control socket. Any local process running as your user can now read terminal contents and inject keystrokes through cmux. Don't enable this on a machine you share, and don't enable it if you run untrusted local tools or browser extensions that could spawn processes. The original config is restored from the `.bak.<timestamp>` file `setup-cmux.sh` writes next to `cmux.json`.

## How it works

- Subscribes to `cmux events` stream (workspace/surface changes).
- Polls `cmux list-pane-surfaces` every 500ms as backup.
- A tab is **busy** when the first non-space character of its cmux title is a Braille glyph (`U+2800-28FF`) — cmux's animated spinner shown while Claude Code is actively working.
- Tab title starting with a sparkle (`✳`) or plain text = idle.
- Click LED → `cmux tab-action --action focus --surface surface:N`.

## Build from source

```bash
swift run                 # dev launch
./build-app.sh            # produces build/cmux-led.app + build/cmux-led.zip for cask release
```

## Release

1. `VERSION=0.1.0 ./build-app.sh`
2. Note the printed `sha256`.
3. `gh release create v0.1.0 build/cmux-led.zip --notes ...`
4. Update `Casks/cmux-led.rb` with new version + sha256, commit, push to the tap repo.

## License

MIT
