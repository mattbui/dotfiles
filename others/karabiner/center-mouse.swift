import AppKit
import ApplicationServices
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("center-mouse: \(message)\n".utf8))
    exit(1)
}

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
        return nil
    }
    return value
}

func elementAttribute(_ element: AXUIElement, _ name: String) -> AXUIElement? {
    guard let value = attribute(element, name), CFGetTypeID(value) == AXUIElementGetTypeID()
    else { return nil }
    return (value as! AXUIElement)
}

func focusedWindowBounds() -> CGRect? {
    // The system-wide AXFocusedApplication query can fail even when the app's
    // Accessibility window queries work. Resolve the frontmost process directly.
    guard let frontmost = NSWorkspace.shared.frontmostApplication else { return nil }
    let app = AXUIElementCreateApplication(frontmost.processIdentifier)
    // Bound the wait for applications that do not respond to Accessibility queries.
    AXUIElementSetMessagingTimeout(app, 0.5)
    guard let window = elementAttribute(app, kAXFocusedWindowAttribute),
          let position = attribute(window, kAXPositionAttribute),
          let size = attribute(window, kAXSizeAttribute),
          CFGetTypeID(position) == AXValueGetTypeID(),
          CFGetTypeID(size) == AXValueGetTypeID()
    else { return nil }

    var origin = CGPoint.zero
    var dimensions = CGSize.zero
    guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
          AXValueGetValue(size as! AXValue, .cgSize, &dimensions),
          origin.x.isFinite, origin.y.isFinite,
          dimensions.width.isFinite, dimensions.height.isFinite,
          dimensions.width > 0, dimensions.height > 0
    else { return nil }
    return CGRect(origin: origin, size: dimensions)
}

func currentScreenBounds() -> CGRect {
    guard let cursor = CGEvent(source: nil)?.location else {
        fail("Cannot read the mouse position.")
    }
    var display = CGDirectDisplayID()
    var count: UInt32 = 0
    guard CGGetDisplaysWithPoint(cursor, 1, &display, &count) == .success, count > 0 else {
        fail("Cannot find the display containing the mouse.")
    }
    return CGDisplayBounds(display)
}

func main() {
    let arguments = Set(CommandLine.arguments.dropFirst())
    let allowed: Set<String> = ["--dry-run", "--screen", "--request-access", "--help"]
    guard arguments.isSubset(of: allowed) else { fail("Unknown argument. Use --help.") }
    if arguments.contains("--help") {
        print("""
        Usage: center-mouse [--dry-run] [--screen] [--request-access]
          --dry-run         Print the target without moving the mouse.
          --screen          Center on the display containing the mouse.
          --request-access  Request Accessibility permission without moving the mouse.
        Default: center in the focused window, falling back to the current screen.
        """)
        return
    }
    if arguments.contains("--request-access") {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        guard AXIsProcessTrustedWithOptions(options as CFDictionary) else {
            fail("Enable Accessibility access in System Settings > Privacy & Security > Accessibility.")
        }
        print("Accessibility access is enabled.")
        return
    }

    var bounds: CGRect
    var target: String
    if arguments.contains("--screen") {
        bounds = currentScreenBounds()
        target = "screen"
    } else {
        guard AXIsProcessTrusted() else {
            fail("Accessibility access is required. Run center-mouse --request-access.")
        }
        if let window = focusedWindowBounds() {
            bounds = window
            target = "focused_window"
        } else {
            bounds = currentScreenBounds()
            target = "screen_fallback"
        }
    }

    // AX window bounds and Quartz cursor positions share global desktop coordinates.
    // Keep negative coordinates for displays to the left of or above the main display.
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    if arguments.contains("--dry-run") {
        print("target=\(target) x=\(center.x) y=\(center.y) bounds=\(bounds)")
        return
    }
    let result = CGWarpMouseCursorPosition(center)
    guard result == .success else { fail("Cannot move the mouse, error \(result.rawValue).") }
}

main()
