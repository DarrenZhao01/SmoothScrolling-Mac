# SmoothScroll

SmoothScroll is a small macOS menu-bar utility that makes mouse-wheel scrolling feel smoother. Free alternative. It intercepts wheel events, converts them into a display-synced stream of small pixel deltas, and leaves trackpad or Magic Mouse scrolling untouched.

This is a personal/local utility, not a packaged app for distribution.

## Features

- Smooth mouse-wheel scrolling driven by a display link.
- Accessibility-based permission flow for event interception/posting.
- Menu-bar controls for enabling/disabling scrolling.
- Adjustable wheel step size, smoothing, and scroll direction.
- Optional launch-at-login using `SMAppService`.

## Requirements

- macOS 13 or later.
- Xcode 26.5 or later for this project configuration.
- Accessibility permission in System Settings.

## Running Locally

1. Open `SmoothScroll.xcodeproj` in Xcode.
2. Build and run the `SmoothScroll` scheme.
3. Grant Accessibility access when prompted, or enable it manually in System Settings > Privacy & Security > Accessibility.
4. Enable smooth scrolling from the settings window or menu-bar item.

For reliable launch-at-login behavior, copy the built app to `/Applications` before enabling the `Launch at login` toggle.

## Notes

The app has App Sandbox disabled because global event interception and synthetic scroll posting are local system-level behaviors. The app is intended to run only on your own Mac.
