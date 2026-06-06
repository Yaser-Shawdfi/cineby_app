---
name: Bug report
about: Report something broken in the cineby_app shell
title: "[Bug] "
labels: ["bug"]
assignees: []
---

## Describe the bug

A clear and concise description of what the bug is.

## To reproduce

Steps to reproduce the behavior:

1. Open the app
2. Tap on…
3. See error…

Expected behavior: what you expected to happen.
Actual behavior: what actually happened.

## Screenshots / screen recordings

If applicable, add screenshots or a screen recording. For WebView issues, a screenshot is far more useful than a written description.

## Environment

- Device: (e.g. Pixel 7, Samsung Galaxy S22, iPhone 14)
- OS version: (e.g. Android 13, iOS 16.5)
- App version / commit: (run `git rev-parse --short HEAD` in the cineby_app directory)
- cineby.at URL you were on when the bug happened: (e.g. https://www.cineby.at/movie/12345)
- Were you on Wi-Fi or cellular?
- Were you using a VPN?

## Logs

If you can reproduce, please attach the relevant logcat / console output. From a debug build:

```bash
adb logcat -s flutter:V
```

## Possible cause

If you have an idea what's going on (e.g. "I think the JS injection in `js_scripts.dart` is being skipped on SPA route changes"), please share.

## Additional context

Anything else that might be relevant.
