# 101

**Explaining Omarchy. Now try it.**

A native Omarchy Quattro plugin that helps you learn your desktop through short explanations and practical exercises. A compact panel stays beside your work. It does not run commands for you.

## Development preview

Implemented: a one-time welcome invitation and seven-lesson tour, hints, previous/next navigation, repeatable exercises, local completion records, optional app/workspace context and contextual suggestions. Terminal and workspace exercises distinguish observed actions from self-confirmed completion.

This is an unvalidated-on-desktop development preview. Portable tests pass; actual Omarchy loading, keyboard focus, screen placement and settings writes need live validation. Source repository: [tcballard/omarchy-101](https://github.com/tcballard/omarchy-101). The welcome-tour expansion is proposed on `feat/welcome-tour-exercises`; no public release has been created.

### Try the checkout on Omarchy Quattro

Check out `feat/welcome-tour-exercises` from this repository. Copy that checkout to `~/.config/omarchy/plugins/io.github.tcballard.omarchy-101/`, then:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.tcballard.omarchy-101
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.tcballard.omarchy-101
omarchy-shell shell summon io.github.tcballard.omarchy-101 '{}'
```

After first enable, 101 offers its welcome tour once. **Not now** dismisses it across restarts; you can summon 101 manually whenever you want. Choose **Start the tour**, or **Continue learning** if progress exists. **Choose a lesson** lets you jump to or repeat any exercise. Context is optional; select **Use desktop context** to enable it for this open session. For an observable lesson, click **Watch me try**, then perform the action. If your app is not recognised, choose **I've done this**. Existing state does not count as a newly performed action.

The preview opens on the shell's default screen. Practise workspace changes on the same monitor you were using when you armed the exercise. Focused-monitor placement remains follow-up work.

Close with the visible button, Escape while the panel has focus, or:

```sh
omarchy-shell shell hide io.github.tcballard.omarchy-101
```

## What screen awareness means here

While explicitly enabled and the guide is open, a lazy-loaded Quickshell Hyprland adapter reads app class, transient window address, monitor name and workspace ID from the existing compositor integration. 101 does not inspect window titles, pixels, clipboard or keystrokes. It neither saves this context nor sends it anywhere. Closing the guide destroys its context adapter and cancels the active exercise.

The host compositor integration itself is shared; disabling 101's adapter does not shut down the shell's own integration. App recognition is deliberately narrow and unknown apps remain unknown.

Progress is saved by Qt Settings in `$XDG_CONFIG_HOME/omarchy-101.ini` (default `~/.config/omarchy-101.ini`). Only lesson IDs and `observed`/`self` evidence are stored. **Reset lesson progress** clears completion. Removing the plugin leaves that file; delete it separately to remove saved progress. The plugin requires no account or model and makes no network requests. **Find my shortcuts** explicitly runs a fixed read-only `hyprctl binds` query. Bash and GNU coreutils (`timeout` and `head`) bound it to 131,073 output bytes and five seconds, with a one-second forced-termination grace. Closing cancels the request; results from cancelled requests are discarded. Binding commands are never executed.

## Lessons and Explaining Omarchy

1. What's so Super about a key?
2. Meet your terminal.
3. Give yourself another desk.
4. Find an app without hunting.
5. Open a window onto the web.
6. Move between your windows.
7. You don't have to remember everything.

`Lessons.js` is the content contract: stable ID, explanation, action, hint and completion rule. These are original companion lessons inspired by Explaining Omarchy, not imported copies of published articles. Future article links should point to verified individual articles.

## Configured shortcuts

**Find my shortcuts** reads the current plain-text binding records. It recognises exact standard action descriptions (including Lua dispatcher records) and numbered workspace dispatchers. It never substitutes default shortcuts when resolution fails. Undescribed custom actions, unsupported modifier masks, unresolved keycodes and bindings in other submaps remain unresolved. Use the menu or mouse in those cases. Run the lookup again after changing bindings.

The welcome service stores its decision separately in the `Welcome` category of the same INI; resetting lesson progress does not re-enable automatic invitations. The welcome offer does not request exclusive keyboard focus or enable observation. It will also appear once for existing preview users updating to this version.

## Next product slices

- Add focused-monitor placement, layout-aware keycode resolution and optional article links.
- Add **Explain this screen** with an explicit capture preview and user-selected model. Never silently upload or continuously capture screenshots; visible screen text is untrusted input, not permission to execute commands.
- Add application-specific guides only where there is a reliable context signal; never claim a user clicked a control from app identity alone.

## Verification

```sh
./tests/run
```

Uses Python 3 for the bundle's manifest validator and Node.js for the pure lesson tests. CI runs these portable checks. See `DESIGN.md` for host evidence and the live verification checklist. The placeholder scaffold image is intentionally not presented as a screenshot.

## Explaining Omarchy companions

101 supports opening a specific lesson from a post's copyable command and showing **Read Tom's explanation** for a curated article mapping. See [ARTICLE-COMPANIONS.md](ARTICLE-COMPANIONS.md). Actual published article URLs are still needed; no article button is shown for unverified mappings.
