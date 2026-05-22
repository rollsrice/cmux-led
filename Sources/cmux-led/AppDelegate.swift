import AppKit
import SwiftUI
import Combine

final class WindowState: ObservableObject {
    @Published var alwaysOnTop: Bool = true
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let monitor = CmuxMonitor()
    let state = WindowState()
    private var cancellables = Set<AnyCancellable>()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = ContentView(
            monitor: monitor,
            alwaysOnTop: stateBinding(),
            onSelect: { [weak self] idx in self?.monitor.selectSurface(index: idx) }
        ).environmentObject(state)

        window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 260, height: 38),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: content)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.makeKeyAndOrderFront(nil)

        applyAlwaysOnTop(state.alwaysOnTop)
        state.$alwaysOnTop
            .sink { [weak self] v in self?.applyAlwaysOnTop(v) }
            .store(in: &cancellables)

        installStatusItem()
        monitor.start()
    }

    private func stateBinding() -> Binding<Bool> {
        Binding(
            get: { self.state.alwaysOnTop },
            set: { self.state.alwaysOnTop = $0 }
        )
    }

    private func applyAlwaysOnTop(_ on: Bool) {
        window.level = on ? NSWindow.Level(Int(CGWindowLevelForKey(.statusWindow)) - 1) : .normal
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "●"
        let menu = NSMenu()
        let pinItem = NSMenuItem(title: "Always on top", action: #selector(togglePin(_:)), keyEquivalent: "")
        pinItem.target = self
        pinItem.state = state.alwaysOnTop ? .on : .off
        menu.addItem(pinItem)
        menu.addItem(NSMenuItem(title: "Show window", action: #selector(showWindow), keyEquivalent: ""))
        menu.items.last?.target = self
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
        state.$alwaysOnTop
            .sink { [weak pinItem] v in pinItem?.state = v ? .on : .off }
            .store(in: &cancellables)
    }

    @objc private func togglePin(_ sender: NSMenuItem) {
        state.alwaysOnTop.toggle()
    }

    @objc private func showWindow() {
        window.makeKeyAndOrderFront(nil)
    }
}
