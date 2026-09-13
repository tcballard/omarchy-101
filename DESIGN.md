# 101: implementation record

2026-09-12 — first development slice.

## Product decision

101 turns Explaining Omarchy into guided practice. A learner chooses a tour or context help, reads one short explanation and does one thing in their real desktop. Hints and skipping are always available. Completion is evidence-labelled. No streak pressure, unsolicited interruptions or automatic command execution.

## Architecture

- ID: `io.github.tcballard.omarchy-101`; name: `101`; provisional version: 0.1.0.
- Kinds: panel (`Panel.qml`) plus singleton first-run service (`Service.qml`); `keepLoaded` retains the current lesson between summons.
- Host lifecycle: `open(payloadJson)` / `close()`; input payload ignored intentionally. Repeated open reuses one surface. Closing stops observation and practice.
- UI: Omarchy `BorderSurface`, `Button`, Color/Style/Border tokens; scrollable at small sizes; on-demand keyboard focus; visible close action and Escape.
- State: panel owns current lesson, hint and exercise baseline. Qt Settings owns durable completion; schema 1, known IDs and evidence enums only. Restore rejects malformed/oversized payloads. A service owns only the one-time welcome decision. No recurring desktop polling is used.
- Context: a lazy-loaded `Context.qml` projects the native Hyprland singleton into bounded scalar values. QML evaluates changes; no external processes or raw socket parser.
- Completion: only events after arming count; workspace change must stay on the baseline monitor and use numbered workspaces. Terminal exercise recognises a fixed app-class set. Manual completion remains separately labelled.
- Dependencies: Omarchy Quattro, its Quickshell Hyprland module, QtQuick and QtCore Settings. Node/Python are development-only.
- Network, credentials, privileged operations: none. User-requested shortcut lookup runs `hyprctl binds` in a fixed, bounded Bash/coreutils pipeline; never dispatches binding commands.
- Failure: missing context leaves self-guided lessons available (including Loader import failure). Unknown apps do not become guessed terminals. A disappearing monitor cannot satisfy a workspace check. Disk-write failures need live verification and user-visible handling before release.
- Removal: host removes plugin; independent progress INI remains, as documented.

## Source evidence

Implementation uses the local v0.3.1 Plugin Skills bundle's design, scaffold, panel, QML and test instructions. Current APIs checked with GitHub on 2026-09-12:

- https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md — blob d62ff7436df9e87b5b7c49be5a5e896cc2446d91; host contract, installation, lifecycle, keepLoaded and tokens.
- https://github.com/omacom/omarchy/blob/quattro/shell/Ui/Button.qml — blob 2b84577a3c553d82203ed5222ba17e54236e2bad; focusable shared controls.
- https://github.com/quickshell-mirror/quickshell/blob/2d3b3e9c70ef380dff751b61d334dc88df016c29/src/wayland/hyprland/ipc/qml.hpp and neighbouring monitor.hpp / hyprland_toplevel.hpp — focusedMonitor, activeWorkspace, activeToplevel, address and lastIpcObject. Installed Omarchy dependency version remains to be tested.

## Evidence and release gate

Portable manifest and lesson tests are runnable through `./tests/run`. Toolkit security lint is advisory. No screenshot, QML execution or installed desktop test is claimed in this environment.

Before releasing:

1. Validate/install from a fresh checkout using the actual Omarchy CLI.
2. Open twice, close via button/Escape/host, disable/re-enable and hot reload; confirm no duplicate windows or retained observation.
3. Check light/dark themes, text scale, small screen, keyboard Tab/Space and two-monitor behaviour; place panel on the invoking monitor.
4. Exercise a terminal already open, a newly focused terminal, unknown app classes, workspace switching and monitor switching. Match observed/self labels to actual evidence.
5. Restart the shell; verify progress restore. Test missing/unwritable settings and provide actionable persistence errors.
6. Confirm local-only context, no screenshot/title persistence, and explicit reset/removal semantics.
7. Verify first-enable invitation, Not now, restart suppression and manual reopening on Omarchy.

## Deferred screen explanation contract

A later Rust helper should own screenshot capture, bounded model requests and cancellation if that slice needs processes/network. User invokes capture, previews/redacts it, chooses local or remote provider and explicitly sends it. Explanations cite visible evidence and distinguish uncertainty; no shell command is executed from screen instructions. Avoid a new service until state ownership requires it.


## 2026-09-13: welcome tour and exercises

- Added first-enable service using the current `PluginShellApi.summon` capability for its own plugin ID. Waits for shell injection; at most five one-second attempts. Panel acknowledges only on opening; decision persists via Qt Settings. No exclusive focus or automatic observation.
- Added launcher (self-confirmed), browser and same-workspace focus exercises. Stable earlier lesson IDs preserve saved completion. A lesson chooser enables repeat practice and the final completion message requires all seven lessons.
- Added explicit shortcut lookup. Plain `hyprctl binds` avoids upstream's documented malformed JSON issue. Exact action descriptions and numbered workspace dispatchers only; unresolved symbols/modifiers/submaps do not become guessed shortcuts. Output capped at the producer, timed process group, cancellation guard, no overlapping requests, no command execution from parsed data. Only numeric workspace arguments survive parsing.
- Sources checked: `shell/services/PluginShellApi.qml` and `bin/omarchy-menu-keybindings` on upstream quattro, 2026-09-13. The latter documents JSON and Lua keycode limitations. 101 does not execute the user's Lua configuration to recover unresolved bindings.
- 21 portable tests pass (lesson transitions, welcome decisions, real-style binding records, limits, submaps, malformed data). Manifest validation passes. Live QML execution, persistence failures, first-enable timing and timeout descendant cleanup on target remain unverified.

## 2026-09-13: article companion support

Added a curated Articles.js catalog and a user-clicked browser link per mapped lesson. No URLs are accepted from IPC payloads. Known lesson IDs can be selected through the existing summon payload; selecting a lesson cancels earlier practice, clears hints and preserves progress. Invalid payloads retain normal opening behaviour. This change adds no custom URI handler or automatic feed fetch.

26 portable tests pass. Actual published article URLs remain unverified; the recovered Super draft title has no active URL. ARTICLE-COMPANIONS.md documents the mapping workflow and copyable per-lesson command. Live QML/browser validation remains outstanding. This builds on the welcome-tour PR rather than duplicating its changes in a main-targeted review.


## 2026-09-13: runtime hardening

The first actual Qt load reproduced two fatal errors: `baseline` redeclared the final Item anchor property, and QtCore Settings does not have `fileName`. Renamed the exercise baseline and switched to the supported `location` URL with encoded path segments.

The Qt harness also reproduced welcome reoffering after immediate reload: assigning the Settings property and calling sync did not synchronously persist the pending property update. Explicit `setValue` before sync fixes it. Real-file write/reload tests now cover this path. Unknown/corrupt progress remains untouched during session practice; reset requires a second confirmation.

Shortcut startup now handles Quickshell FailedToStart, which emits runningChanged but no exited signal; a seven-second UI watchdog is an additional fallback. Real process tests found the TERM-plus-grace wrapper could outlive its supervisor through TERM-ignoring descendants. A GNU timeout KILL deadline plus SIGALRM cancellation now terminates the whole group in both tested paths (about 5.1 seconds at timeout and 0.4 seconds on cancellation).

GuideButton scrolls keyboard-focused controls into view and exposes accessible button names. The offscreen Qt window test verifies focus scrolling and Escape propagation. Exercise methods reject invalid indexes, closed-panel completion and unavailable observation; selection disarms practice before changing state.

Validation: 31 Node tests; actual Qt 6.11.2 QML load/lifecycle with narrowly substituted host boundaries; real QtCore on-disk persistence; native pipeline timeout/cancellation. CI includes all three layers. No live Omarchy session is available. Do not equate the harness with host integration or release readiness. QtCore Settings has no exposed write-error status: disk-full/read-only UI reporting remains a known limitation.
