# 101: implementation record

2026-09-12 — first development slice.

## Product decision

101 turns Explaining Omarchy into guided practice. A learner chooses a tour or context help, reads one short explanation and does one thing in their real desktop. Hints and skipping are always available. Completion is evidence-labelled. No streak pressure, unsolicited interruptions or automatic command execution.

## Architecture

- ID: `io.github.tcballard.omarchy-101`; name: `101`; provisional version: 0.1.0.
- Kind: panel, hosted `Panel.qml`; `keepLoaded` retains the current lesson between summons.
- Host lifecycle: `open(payloadJson)` / `close()`; input payload ignored intentionally. Repeated open reuses one surface. Closing stops observation and practice.
- UI: Omarchy `BorderSurface`, `Button`, Color/Style/Border tokens; scrollable at small sizes; on-demand keyboard focus; visible close action and Escape.
- State: panel owns current lesson, hint and exercise baseline. Qt Settings owns durable completion; schema 1, known IDs and evidence enums only. Restore rejects malformed/oversized payloads. No service or polling required.
- Context: a lazy-loaded `Context.qml` projects the native Hyprland singleton into bounded scalar values. QML evaluates changes; no external processes or raw socket parser.
- Completion: only events after arming count; workspace change must stay on the baseline monitor and use numbered workspaces. Terminal exercise recognises a fixed app-class set. Manual completion remains separately labelled.
- Dependencies: Omarchy Quattro, its Quickshell Hyprland module, QtQuick and QtCore Settings. Node/Python are development-only.
- Network, credentials, privileged operations: none.
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
7. Add first-enable tour offer before describing this as automatic onboarding.

## Deferred screen explanation contract

A later Rust helper should own screenshot capture, bounded model requests and cancellation if that slice needs processes/network. User invokes capture, previews/redacts it, chooses local or remote provider and explicitly sends it. Explanations cite visible evidence and distinguish uncertainty; no shell command is executed from screen instructions. Avoid a new service until state ownership requires it.
