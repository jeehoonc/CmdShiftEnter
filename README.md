# ExpandWindowHotKey
Hot key macOS app to expand current focused window to the maximum possible frame of the screen.

Troubleshooting
-

#### The debug build does not have accessibility permissions granted (i.e. `AXIsProcessTrustedWithOptions` returns `false`).
https://stackoverflow.com/questions/52214771<br>
The XCode project should be saved as a 'workspace' (Files > Save As Workspace...). In workspace settings (Files > Workspace Settings...), set "Drived Data" to "Workspace-relative Location". Once the build is produced, add the build to accessibility (Spotlight Search > System Settings > Privacy & Security > Accessibility > "+" > Select the product build under `DerivedData/<project-name>/Build/Products/`).

#### AXUIElement API (e.g. `AXUIElementCopyAttributeValue`) returns `-25204` (`.cannotComplete`).
https://stackoverflow.com/questions/27694912<br>
The XCode project should disable [`App Sandbox` entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.app-sandbox).
