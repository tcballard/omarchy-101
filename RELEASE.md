# v0.1.0 preparation

Status: candidate preparation, **not released**. Manifest remains 0.1.0 because
there has been no public release. The final tag must identify merged, tested main.

## Release notes draft

101 helps new Omarchy users learn by doing: a welcome invitation, seven guided
lessons, hints and repeat practice. Optional app/workspace context can recognise
some exercises; manual confirmation is always available. Configured shortcut
lookup is requested explicitly. No screenshots or network requests are made.

Progress and welcome choices use atomic local files with visible save errors and
Retry. Existing INI progress migrates without modifying the original file. Future
or unreadable state is protected. Article companion commands are supported;
individual article links stay hidden until their publication is verified.

## Evidence and remaining gates

- Portable suite: 31 tests, including native shortcut process cleanup.
- Qt 6.11.2 offscreen suite: loading, lesson selection, focus/Escape, migration,
  queued saves, actual QSaveFile disk failure/retry, reset, schema protection,
  process boundary failures and welcome lifecycle.
- This suite substitutes FileView, shell and compositor boundaries; it is not
  evidence of native Quickshell or Hyprland integration.
- LIVE-TEST.md: not run; no Omarchy/Hyprland session available in the build environment.
- Actual host preview: pending live capture.
- Article publication: omarchy.tcballard.dev/explaining could not be verified;
  no mappings were activated. This does not block self-contained lessons.
- Marketplace ownership/permission attestations: require Tom's confirmation.

## Build a candidate archive

Run `python3 scripts/package.py /absolute/path/to/new-output-directory` from a
clean committed checkout. It produces a source archive, source/release manifests,
a source-package SPDX SBOM and SHA256SUMS bound to the exact commit/tree. It does
not tag, upload or attest to live compatibility. Runtime dependencies are supplied
by the host; none are bundled. Development/test tools are not runtime dependencies.

After this PR merges and CI plus live acceptance pass, rebuild from that exact
main SHA, verify checksums and the bundle's release preflight, then create the
annotated v0.1.0 tag and GitHub release. Verify downloaded assets against their
manifests before marketplace submission. Do not reuse a candidate archive for a
different commit, even if its source files look similar.
