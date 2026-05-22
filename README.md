# cmux-led

![cmux-led overlay showing one green idle LED and one red busy LED with white focus ring](docs/screenshot.png)

Floating macOS overlay. One LED per tab in your current [cmux](https://cmux.com) workspace.

- 🟢 idle — Claude waiting on you
- 🔴 busy — Claude working
- white ring — focused tab
- click LED → focus that tab in cmux

## Install

```bash
brew tap rollsrice/cmux-led
brew install --cask cmux-led
```

The installer asks once for permission to enable cmux external socket control (`automation.socketControlMode = "allowAll"`). Click **Enable**, then **Restart cmux now** when prompted. Your original cmux config is backed up.

First app launch: right-click → Open (ad-hoc signed; Gatekeeper warns once).

> Security: `allowAll` lets any local process drive cmux (read panes, inject keystrokes). Don't enable on shared machines.

## Build from source

```bash
swift run                      # dev launch
VERSION=0.1.2 ./build-app.sh   # release zip + sha256 for cask
```

Source-only install path (no brew): run `./setup-cmux.sh` to flip cmux config, then restart cmux.

## License

MIT
