# CmdShiftEnter
A macOS app to expand/unexpand current focused window to/from the maximum size of the screen.

Usage
-
- Press `Cmd + Shift + Enter` (or your own [Hot Key](#hot-key)) to expand current focused window.
- Press `Cmd + Shift + Enter` (or your own [Hot Key](#hot-key)) to unexpand the expanded window to its original size.

> [!WARNING]
> It does nothing if the window was already expanded to the maximum size by some other modifications than this app.

Settings
- 
### Hot Key

> [!NOTE]  
> `Cmd + Shift + Enter` is the default.

1) Go to "Foo" -> "Settings"
2) Press any key combination that you'd like to configure as your "Hot Key".
3) Click "Save". Now the combination you just saved is now your new "Hot Key".

Development
-

### Coding
- This project often refrain from using [Extensions](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/extensions/) just to bypass the visibility constraints of their member variables/functions. It rather extends only if the class really needs a proper extension (e.g. when it actually implements some mechanisms to be used by multiple callers).

### Challenges (during development)

#### NSScreen.Screens Coordinates don't align with AXUIElement coordinates for multi-monitor displays
https://github.com/tmandry/Swindler/issues/62<br>
https://github.com/rxhanson/Rectangle/issues/15

#### AXUIElement API does not have public API to retrieve unique window ID
https://stackoverflow.com/questions/1742890/<br>
https://stackoverflow.com/questions/6178860/<br>
https://github.com/withfig/challenge-window-events?tab=readme-ov-file#tips<br>
As discussed in the links above, this is known problem that there is no public API to get the window ID. The solution is to somehow use the old API implemented in object-c - `_AXUIElementGetWindow`. There exist two known ways to have this API accessible in your XCode project.
1) Declare `_AXUIElementGetWindow` function in a `.swift` file as below and use it. Note: this is how [alt-tab-macos](https://github.com/lwouis/alt-tab-macos/) uses it (see [`src/api-wrappers/PrivateAPIs.swift:174`](https://github.com/lwouis/alt-tab-macos/blob/f7de2bb6d9ee54686fd5761c939420b5d7f56e1e/src/api-wrappers/PrivateApis.swift#L174)).
```swift
import AppKit

@_silgen_name("_AXUIElementGetWindow") @discardableResult
func _AXUIElementGetWindow(_ axUiElement: AXUIElement, _ wid: inout CGWindowID) -> AXError
```
2) Declare `_AXUIElementGetWindow` function in a `.h` file as below, reference this header file to your project from the build settings, and then use it. Note: this is how [Rectangle](https://github.com/rxhanson/Rectangle/) uses it (see [`Rectangle/Rectangle-Bridging-Header.h`](https://github.com/rxhanson/Rectangle/blob/59e17b3397642dced24e20a3b08108f64ab38b58/Rectangle/Rectangle-Bridging-Header.h)).
```swift
#import <AppKit/AppKit.h>

AXError _AXUIElementGetWindow(AXUIElementRef element, uint32_t *identifier);
```

#### The debug build does not have accessibility permissions granted (i.e. `AXIsProcessTrustedWithOptions` returns `false`).
https://stackoverflow.com/questions/52214771<br>
The XCode project should be saved as a 'workspace' (Files > Save As Workspace...). In workspace settings (Files > Workspace Settings...), set "Drived Data" to "Workspace-relative Location". Once the build is produced, add the build to accessibility (Spotlight Search > System Settings > Privacy & Security > Accessibility > "+" > Select the product build under `DerivedData/<project-name>/Build/Products/`).

#### AXUIElement API (e.g. `AXUIElementCopyAttributeValue`) returns `-25204` (`.cannotComplete`).
https://stackoverflow.com/questions/27694912<br>
The XCode project should disable [`App Sandbox` entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.app-sandbox).
