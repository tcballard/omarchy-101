# Explaining Omarchy × 101

Each published explanation can point to a practical lesson. Each lesson can link back to the verified article. Lessons remain usable offline; opening the full article is a user action in the browser.

## Publication home

Tom's chosen Omarchy publication home is `https://omarchy.tcballard.dev`.

- `/explaining`: Explaining Omarchy index.
- `/explaining/<article-slug>`: individual explanations and 101 companions.
- `/today`: proposed home for Today in Omarchy.
- The root can collect other Omarchy writing, projects and resources.

101 accepts individual HTTPS explanation URLs on this exact host, including an optional trailing slash. Index pages and other sections are not lesson article targets. Existing X links can remain as original-publication references. These are URL conventions, not a claim that the website or pages have been deployed.

## Post companion commands

These commands open a lesson in an installed, enabled 101 containing this change. They do not install the plugin, mark an exercise complete, turn on observation or run lesson actions.

| Topic | Lesson ID |
| --- | --- |
| Super key | `super` |
| Terminal | `terminal` |
| Workspaces | `workspace` |
| Application launcher | `launcher` |
| Browser | `browser` |
| Window focus | `focus` |
| Finding help | `help` |

Example for the Super article:

```sh
omarchy-shell shell summon io.github.tcballard.omarchy-101 '{"lesson":"super"}'
```

Replace `super` with another ID from the table. Unknown or malformed requests open the normal guide without selecting an arbitrary lesson. This is a copyable command, not a registered browser deep-link scheme.

## Publishing a companion

1. Verify the actual published article and select the lesson it supports.
2. Add its exact title and canonical HTTPS URL under that lesson ID in `Articles.js`.
3. Run `./tests/run`; verify the article opens correctly from the live plugin.
4. Publish the plugin update containing that mapping.
5. Add the matching command to the post, explaining that 101 must be installed and updated first.

The plugin displays **Read Tom's explanation** only for entries with a valid URL and title. It accepts individual /explaining/<article-slug> URLs on omarchy.tcballard.dev, canonical article paths on tcballard.substack.com or tcballard.dev, and tcballard status links on x.com. Additional publishing hosts need an explicit update to the validator. This syntax check does not establish that an article exists; publication verification is a separate authoring step.

## Current mapping status

The title “What’s so Super about a key?” was recovered from prior draft context. Its canonical published URL has not been verified. It is recorded with an empty URL and the article button stays hidden. No other published article-to-lesson mapping is claimed.

No existing post has been edited. A published post URL or series index is needed to finish the first real mapping.
