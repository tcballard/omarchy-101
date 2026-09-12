# 101

**Explaining Omarchy. Now try it.**

A native Omarchy Quattro plugin that helps you learn your desktop through short explanations and practical exercises. A compact panel stays beside your work. It does not run commands for you.

## Development preview

Implemented: a four-lesson welcome tour, hints, previous/next navigation, repeatable exercises, local completion records, optional app/workspace context and contextual suggestions. Terminal and workspace exercises distinguish observed actions from self-confirmed completion.

This is an unvalidated-on-desktop development preview. Portable tests pass; actual Omarchy loading, keyboard focus, screen placement and settings writes need live validation. Source repository: [tcballard/omarchy-101](https://github.com/tcballard/omarchy-101). The implementation is proposed on `feat/guided-learning-preview`; no public release has been created.

### Try the checkout on Omarchy Quattro

Check out `feat/guided-learning-preview` from this repository. Copy that checkout to `~/.config/omarchy/plugins/io.github.tcballard.omarchy-101/`, then:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.tcballard.omarchy-101
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.tcballard.omarchy-101
omarchy-shell shell summon io.github.tcballard.omarchy-101 '{}'
```

Choose **Start the tour**. Context is optional; select **Use desktop context** to enable it for this open session. For an observable lesson, click **Watch me try**, then perform the action. If your app is not recognised, choose **I've done this**. Existing state does not count as a newly performed action.

The preview opens on the shell's default screen. Practise workspace changes on the same monitor you were using when you armed the exercise. Automatic first-enable opening and focused-monitor placement are follow-up work.

Close with the visible button, Escape while the panel has focus, or:

```sh
omarchy-shell shell hide io.github.tcballard.omarchy-101
```

## What screen awareness means here

While explicitly enabled and the guide is open, a lazy-loaded Quickshell Hyprland adapter reads app class, transient window address, monitor name and workspace ID from the existing compositor integration. 101 does not inspect window titles, pixels, clipboard or keystrokes. It neither saves this context nor sends it anywhere. Closing the guide destroys its context adapter and cancels the active exercise.

The host compositor integration itself is shared; disabling 101's adapter does not shut down the shell's own integration. App recognition is deliberately narrow and unknown apps remain unknown.

Progress is saved by Qt Settings in `$XDG_CONFIG_HOME/omarchy-101.ini` (default `~/.config/omarchy-101.ini`). Only lesson IDs and `observed`/`self` evidence are stored. **Reset lesson progress** clears completion. Removing the plugin leaves that file; delete it separately to remove saved progress. The plugin requires no account or model. It makes no network requests and launches no external commands.

## Lessons and Explaining Omarchy

1. What's so Super about a key?
2. Meet your terminal.
3. Give yourself another desk.
4. You don't have to remember everything.

`Lessons.js` is the content contract: stable ID, explanation, action, hint and completion rule. These are original companion lessons inspired by Explaining Omarchy, not imported copies of published articles. Future article links should point to verified individual articles.

## Next product slices

- Offer the welcome tour once after first enable, with a durable “not now” choice.
- Resolve the user's actual shortcut bindings and show those in each exercise.
- Add a lesson chooser, keyboard/window exercises and optional article links.
- Add **Explain this screen** with an explicit capture preview and user-selected model. Never silently upload or continuously capture screenshots; visible screen text is untrusted input, not permission to execute commands.
- Add application-specific guides only where there is a reliable context signal; never claim a user clicked a control from app identity alone.

## Verification

```sh
./tests/run
```

Uses Python 3 for the bundle's manifest validator and Node.js for the pure lesson tests. CI runs these portable checks. See `DESIGN.md` for host evidence and the live verification checklist. The placeholder scaffold image is intentionally not presented as a screenshot.
