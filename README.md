# discourse-tc-topic-next-button

A Discourse theme component that adds a **Next Topic** button above the topic
timeline, letting readers step through a topic list one topic at a time
without returning to the list between topics.

This is a maintained fork of
[paviliondev/discourse-tc-topic-next-button](https://github.com/paviliondev/discourse-tc-topic-next-button).

## How it works

The button uses Discourse core's `topic-list-tracker`, the same mechanism
behind the `g`,`j` / `g`,`k` keyboard shortcuts. Core tracks the **last topic
list you visited** (a category, `/latest`, `/new`, a tag, …), so the button
advances through that list in the order you saw it.

Because of that, the button only appears when it has somewhere sensible to
go. It hides itself when:

- the current topic isn't part of the last list you visited (for example,
  you arrived via a suggested topic, search result, or notification),
- you've reached the end of the list, or
- the topic's category isn't in the `topic next categories` setting (when set).

When the list has more pages, reaching the end of the loaded page
automatically fetches the next page and keeps going.

## Settings

| Setting | Default | Description |
| --- | --- | --- |
| `topic next always go to first post` | `true` | Navigate to the first post of the next topic. When off, navigates to the next unread post. |
| `topic next categories` | *(blank)* | Restrict the button to these categories. Blank shows it everywhere. |

The button label ("Next Topic") can be translated or reworded by editing the
`topic_next_label` text in the theme's locale settings. On mobile the button
shows the chevron icon only.

## Installation

Admin → Customize → Themes → **Install** → *From a git repository*, then add
this repo's URL and include the component in your active theme(s).

Requires a Discourse version with `.gjs` theme support (any release from
2024 onward).

## Changes in this fork

- **Fixed the button looping back over the same topics.** The old version
  called core's stateful `nextTopicUrl()` on every render, corrupting the
  shared list pointer (which also broke the `g`,`j` shortcut and skipped
  topics). When the pointer was lost, core silently restarted from the top
  of the list. The button now validates the next topic without disturbing
  tracker state and hides instead of looping.
- **Restored the `topic next categories` setting**, which had been dropped
  in an earlier refactor and did nothing.
- **Converted to a single-file `.gjs` component**, resolving Discourse's
  `.hbs`-extension deprecation notice.
- **Fixed button placement** for modern plugin-outlet markup: it now sits
  directly above the timeline.
- Safer "go to first post" URL handling (works on subfolder installs and
  URLs without a post number).
