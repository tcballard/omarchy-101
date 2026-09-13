# 101 live acceptance

Status: **not run**. Requires your Omarchy Quattro session. Record the plugin full
SHA, Omarchy full SHA/version, Qt and Quickshell versions, monitor layout and
results. Do this in a disposable user/session for fresh-install and storage-failure
checks; do not alter your everyday progress or fill your actual system disk.

## Install and identity

```sh
omarchy plugin add https://github.com/tcballard/omarchy-101.git
cd ~/.config/omarchy/plugins/io.github.tcballard.omarchy-101
# For an unmerged candidate, fetch/check out the exact SHA from its PR first.
git rev-parse HEAD
omarchy version
omarchy plugin validate .
omarchy plugin enable io.github.tcballard.omarchy-101
```

1. Fresh state: welcome appears once. Not now closes it. Restart the shell through
   Omarchy's menu: no second invitation. Summon manually and start the tour.
2. Exercise all seven lessons. Super/launcher/help have manual confirmation.
   Terminal/browser/focus/workspace support Watch me try after enabling context.
   Existing app focus must not count as a new action; workspace checks use the
   same monitor. Manual fallback remains available.
3. Find my shortcuts shows configured bindings or a clear unresolved result.
   Close during lookup: no late results or lingering helper. Reopen and retry.
4. Tab through every control on a short screen; focused buttons scroll into view.
   Escape closes. Check each monitor and the default-screen placement limitation.
5. Close/reopen and restart: completed lessons and current selection survive.
   Context is off again. Reset requires confirmation and does not reset welcome.
6. Summon a lesson while loading and after loading:

```sh
omarchy-shell shell summon io.github.tcballard.omarchy-101 '{"lesson":"terminal"}'
```

## Storage failures in the disposable session

- Make the plugin's test config directory unwritable as the ordinary test user.
  Complete a lesson: failure text appears; completion stays visible. Restore write
  permission; Retry saving succeeds. Restart and confirm the completion remains.
- Repeat for welcome choice and reset. A failed reset must remain visibly unsaved.
- On a disposable constrained filesystem, exhaust only that filesystem's capacity
  and repeat. An unsuccessful atomic write must preserve the prior save bytes.
- Start with a valid old INI and no JSON: legacy completion/choice restore. Complete
  a lesson and check JSON creation; original INI bytes must be unchanged.
- Use malformed JSON, a future version, and unreadable JSON separately. No automatic
  replacement. Only malformed/future data permits the explicit reset path.
- Make several selections/completions during a pending write: latest state wins.
  Close/reopen while pending and test disable/re-enable after saving completes.

## Update, removal, preview

```sh
omarchy plugin update io.github.tcballard.omarchy-101
omarchy plugin remove io.github.tcballard.omarchy-101
```

Confirm update preserves progress; removal unloads the panel and service while
leaving only the documented state files. Reinstall and confirm restoration.
Capture the actual panel on the tested host as root preview.png before release.
Do not use an offscreen harness image as evidence of Omarchy appearance.

Record each result as pass/fail/not run and include only redacted relevant logs.
