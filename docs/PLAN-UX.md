# Tsumugi Mobile: UX Plan

> **Status:** draft v3, 2026-11-15: the "may do now" items (U2, U3, U4, U13, U14, U15, U17) are **done** and tested; the items that need real people (U1, U16, and everything gated on round 1) are **not done**. Section 4 and 9 show the new status. v2 added an assumptions register (section 2), a standards and research review with sources (section 3) and a check of the build against those standards (section 4).
> **Scope:** the experience side of the app: who it is for, what they do, how well the current build supports it, how we will find out, and what to change next. The visual system, components and engineering phases are in [PLAN-MOBILE-UI.md](PLAN-MOBILE-UI.md); data, routes and website parity are in [PLAN-FLUTTER-MOBILE.md](PLAN-FLUTTER-MOBILE.md).
> **Boundary (unchanged):** a play-demo. No backend, no online services, nothing saved on the device, no permissions. Everything a person does lives in memory and resets on restart. UX work must not add accounts, sync, analytics, notifications or sharing.

## 0. Honest starting point

- The app has been seen by **one developer on one phone** (Samsung Galaxy A05s, Android 15). **No one else has used it.** Every statement about users is an **assumption to test** (section 2), not a finding.
- What *is* measured: cold start 517 to 677 ms, median frame 11 ms while scrolling Tasks, automated accessibility guidelines pass in light and dark at 100% and 160% text.
- What the research in section 3 adds: the standards the app should be held to, and **four things the build gets wrong or has not checked** (section 4): the Undo toast timing, non-text contrast of borders, reflow at narrow widths, and the participant plan. These are now in the backlog.
- What is still not done: usability sessions, a TalkBack walkthrough, a content and microcopy review.

## 1. UX goals

| # | Goal | How we will know |
|---|---|---|
| G1 | A first-time person understands what Tsumugi is for within the first minute and reaches a useful screen without help | Session tasks 1 and 2 (section 7): reached Home and named what the app does, no prompts |
| G2 | The daily loop (see what is due, do it, tick it off) takes one hand and a few seconds | Complete and reschedule in one gesture; time on task |
| G3 | The "why behind the work" idea (objective, requirement, task, file, change) is discoverable without reading the guide | Session task 6 |
| G4 | Nothing is lost by accident, and every change can be undone | No data-loss comments; Undo used successfully, including with a screen reader |
| G5 | Everyone can use it: large text, dark mode, screen reader, reduced motion, one hand | TalkBack walkthrough passes; automated checks stay green; section 4 gaps closed |
| G6 | The demo is honest: a person always knows what is real in the session and what is only a preview | No participant believes something was saved; no "dead" buttons |

## 2. Assumptions register

Everything the plan depends on that has **not** been verified. Each has a risk if wrong and the cheapest way to check. Status: **U** untested, **P** partly supported by something we measured or read, **V** verified. At the time of writing nothing is V.

### 2.1 About people

| # | Assumption | If wrong | How to check | Status |
|---|---|---|---|---|
| A1 | The audience is two groups: solo makers (writers, illustrators, hobby developers) and evaluators (clients, teachers, teammates judging the demo) | Tasks, wording and priorities aim at the wrong person | Ask 5 to 8 real people about their own work before large redesign (R1, section 7.1) | U |
| A2 | Solo makers juggle several projects and check the phone between sessions on a laptop | "Up now" and "Continue" on Home matter less than assumed | Interview questions in 7.1 | U |
| A3 | People use the phone with **one hand and a thumb** much of the time | Bottom-heavy layout adds little; top actions would be fine | Observe grip in sessions; background: one observational study found about 49% one-handed use ([Hoober, 2013](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php?)), by its author's own account not scientific and excluding tablets | P |
| A4 | Evaluators decide within a few minutes and will not read Help | The Welcome page and first screens carry the whole pitch | Task 1 and 2 timings and think-aloud | U |
| A5 | Many users run dark mode and large text | Time spent on dark mode and text size is partly wasted | Ask in sessions; check Account settings usage in the test phone | U |
| A6 | Participants already know words like task, project, milestone; "requirement" and "deliverable" need explanation | Vocabulary is either too heavy or over-explained | Task 6 and post-session questions | U |
| A7 | People will find swipe and long-press on their own or learn them from a short hint | Core efficiency features go unused | Task 3 and 4: watch which gesture they try first | U |

### 2.2 About context and devices

| # | Assumption | If wrong | How to check | Status |
|---|---|---|---|---|
| A8 | Typical phone is Android 12 or newer, 360 to 412 dp wide, 60 to 120 Hz | Layout or performance tuned for the wrong device | Test on a small (320 to 360 dp) and a large phone; keep the A05s as the low-end reference | P (one device) |
| A9 | The app is used briefly (seconds to a few minutes) and often interrupted | Long flows and unsaved state hurt more than expected | Observe interruptions; note in sessions | U |
| A10 | The sample data (about 20 tasks, 3 projects) is representative enough to judge the product | Real-sized data exposes problems the demo hides (long titles, 100+ tasks) | 500-task test exists for performance only; add long-title and many-project cases | P |
| A11 | Android only is acceptable for the audience | Evaluators on iPhone cannot try it | Ask in recruitment which phone people use | U |

### 2.3 About the product and constraints

| # | Assumption | If wrong | How to check | Status |
|---|---|---|---|---|
| A12 | The play-demo boundary (no saving, no backend) is understood and accepted by participants | Frustration, or people think work is saved | Session task 9 | U |
| A13 | Real in-session actions with Undo are clearer than preview sheets | People expect persistence and lose trust when it resets | Task 9 and 12 follow-up | U |
| A14 | Keeping the website's identity (Fredoka, palette, vocabulary) helps recognition | The font or palette hurts legibility at small sizes or dark mode | Watch for reading errors; large-text check (done automatically to 200%) | P |
| A15 | The individual workspace should show no team concepts | Evaluators expect collaboration features and judge the app thin | Ask about missing features after the session | U |

### 2.4 About the evidence and the method

| # | Assumption | If wrong | How to check | Status |
|---|---|---|---|---|
| A16 | Automated accessibility checks plus a TalkBack pass are enough to find the serious access problems | Real assistive-technology users hit blockers | Include at least one real screen-reader or large-text user in round 1 | P (automation only) |
| A17 | Five users find most problems | Several distinct groups need more people | Follow the group rule in section 3.4: 3 to 4 per distinct group, several rounds | P |
| A18 | The performance targets (cold start under 700 ms, no frame over 25 ms) are what people feel | Smooth numbers but slow-feeling flows | Ask about speed in sessions; the platform's own "excessive" threshold is 5 s cold start | P |
| A19 | The standards in section 3 are the right bar for a student/portfolio demo | Over- or under-investing in compliance | Owner decision X6 | U |

## 3. Research: standards and basics

What was read, what it says, and what it means for this app. Sources are official where possible; where only secondary sources were found, that is stated. Search results were summarised, not read in full, unless marked **(read)**.

### 3.1 Touch targets and spacing

- **WCAG 2.2, 2.5.8 Target Size (Minimum), Level AA (read):** pointer targets must be at least 24 by 24 CSS pixels, unless: a 24 px circle centred on the target does not touch another target (spacing), the same function exists in another control on the page, the target is inline text, the browser controls its size, or the size is essential. 2.5.5 (Level AAA) asks for 44 by 44. [W3C Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html); overview: [TetraLogical](https://tetralogical.com/blog/2023/10/05/whats-new-wcag-2.2).
- **Android:** Google's accessibility help advises each interactive element be at least **48 by 48 dp** (about 9 mm) ([Google Accessibility Help](https://support.google.com/accessibility/android/answer/7101858)). This is a platform guideline, not a WCAG requirement.
- **For us:** our rule (48 dp, enforced by `androidTapTargetGuideline` in tests) is stricter than both WCAG levels except the AAA 44 px, which 48 dp also exceeds. Keep it. Not enough by itself: crowded targets still hurt, so the spacing exception is irrelevant while every target is already 48 dp.

### 3.2 Gestures and alternatives

- **WCAG 2.5.1 Pointer Gestures, Level A:** anything that needs a path-based gesture (a swipe) or a multi-point gesture must also work with a single pointer without that path; a single-pointer alternative cannot itself be another swipe. **2.5.7 Dragging Movements, Level AA (2.2):** anything dragged needs a simple pointer alternative ([W3C Understanding 2.5.1](https://www.w3.org/WAI/WCAG22/Understanding/pointer-gestures), [2.5.7](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements)). Secondary reading found these pages' editor's-draft copies; the exact wording should be checked against the published text before quoting.
- **Android:** custom accessibility actions are the standard alternative to hidden swipes; a screen reader shows them as a menu on the item ([Android codelab: testing for accessibility](https://developer.android.com/codelabs/basic-android-kotlin-compose-test-accessibility)).
- **Discoverability:** Norman and Nielsen argued that hidden gestures and removed visible controls hurt usability ([summary](https://ignorethecode.net/blog/2010/05/30/nielsen_and_norman_on_gestures/)). A swipe-revealed-widget study from Inria examines how people discover such controls ([overview of findings](https://uxdesign.cc/discoverability-in-the-age-of-touchscreens-125fcb392e08)). One blog's claim that 30 to 50% of first-time users discover gesture-only controls has no source and is **not used**.
- **For us:** swipe right/left on a task tile is never the only way: the status circle completes, the long-press menu does everything, custom accessibility actions mirror it. That satisfies 2.5.1 in design. The weakness is **discoverability** (A7), not access.

### 3.3 Text size, reflow and contrast

- **WCAG 1.4.4 Resize Text (AA):** text can be enlarged to 200% without losing content or function. **1.4.10 Reflow (AA, 2.1):** content works at 320 CSS px wide (about 400% zoom) without two-dimensional scrolling, except where two-dimensional layout is essential. **1.4.11 Non-text Contrast (AA, 2.1):** parts of the interface needed to identify controls and their states, and graphics that carry meaning, need at least **3:1** contrast against neighbours ([overview and criticism of how 1.4.4 and 1.4.10 relate](https://www.yatil.net/blog/resize-text-reflow); secondary source, verify against the Understanding documents).
- **Dark theme (Material, M2 documentation):** use a dark grey surface (#121212 in the guideline) rather than pure black, show elevation with lighter surfaces, desaturate accent colours so they do not vibrate, and keep body text well above 4.5:1; the page cites 15.8:1 for white on its dark surface ([Material dark theme](https://m2.material.io/design/color/dark-theme)). This documentation is for Material 2 and should be rechecked against current Material 3 pages.
- **For us (measured from our palette):** dark body text on canvas 16.0:1, on cards 14.8:1; muted text on cards 8.2:1. Our dark canvas `#17141C` is a tinted dark grey, consistent with the guidance. **Border contrast is low:** the dark `lineStrong` border on a card is 1.66:1 and the light one about 1.5:1, below 3:1 (see 4).

### 3.4 Usability testing method

- **How many people (read):** [Nielsen Norman Group](https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/) recommends about **5 users per test** and as many small tests as you can afford (for example three rounds of 5 rather than one of 15), retesting after each redesign. When there are **several distinct user groups, test 3 to 4 per group (3 per group when there are three or more)**. Quantitative metrics need about **20** users; card sorting about 15. The "85% of problems" figure comes from older work and is repeated by many blogs.
- **Benchmarks:** the single ease question (SEQ, 7 points) averages **5.5** across tasks, and the System Usability Scale (SUS) averages **68** across 500 products, where 68 is the 50th percentile and not a pass mark ([MeasuringU summaries](https://measuringu.com/?p=170)). Both are secondary summaries of work by Sauro and Lewis; SUS is unreliable with five people, so it is optional here.
- **For us:** our v1 plan of "5 people, mixed groups" does not fit the NN/g rule. Section 7 changes it to **3 to 4 per group over two rounds**, treats all numbers as indicative, and drops hard percentage targets.

### 3.5 Feedback, status and Undo

- **Undo over confirmation:** practitioner consensus (and Nielsen's heuristics on error prevention) is that confirmation dialogs work only when rare and that reversible actions need no confirmation ([overview](https://blog.logrocket.com/ux-design/ux-error-prevention-examples/)). No controlled study comparing the two was found; treat it as expert consensus. We already follow it.
- **Timing of toasts with an action:** WCAG 2.2.1 (Timing Adjustable) is argued both ways for auto-dismissing toasts; critics say a toast with an action such as Undo can fail it because people cannot extend the time ([W3C WAI list thread](https://lists.w3.org/Archives/Public/w3c-wai-ig/2025AprJun/0085.html), [A11y toast essay](https://scottohara.me/blog/2019/07/08/a-toast-to-a11y-toasts.html)). **Flutter itself changed** (3.38): a `SnackBar` with an action no longer auto-dismisses; it stays until acted on or dismissed, aligning with the Material 3 spec and improving accessibility; `persist: false` restores the old behaviour ([Flutter breaking change (read)](https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update)). Before that, Flutter kept it open only when TalkBack was on.
- **Status messages, WCAG 4.1.3 (AA):** status messages must be announced without moving focus; on Android that means a live region ([overview](https://wcag.dock.codes/documentation/wcag413)). Android-specific official guidance was thin in the results; verify the exact API behaviour on device with TalkBack.
- **For us:** our own `UndoToast` disappears after 5 seconds regardless, which is **weaker than the platform's current behaviour** for the one control that undoes a change (see 4).

### 3.6 Onboarding, hints and empty states

- [NN/g on app tutorials](https://www.nngroup.com/articles/onboarding-tutorials/): walkthrough tutorials are overused and people often skip them; they can help for genuinely novel interactions. Practitioner sources agree: show help at the point of need, do not stack several coach marks, treat empty states as invitations with one clear action (secondary sources: [Shopify](https://www.shopify.com/partners/blog/mobile-app-onboarding), [Livefront](https://medium.com/livefront/put-me-in-coach-marks-8146c61ca875)).
- **For us:** a full-screen tour would go against this. The right size is **one contextual hint, once, on the first task tile**, replayable from Account, and only if sessions show swipe is missed (A7).

### 3.7 Android platform behaviour

- **Edge-to-edge and back:** from Android 15 apps that target API 35 are drawn edge-to-edge by default (opt-out removed for API 36); the predictive-back flag `enableOnBackInvokedCallback` is now an opt-out and Android 16 turns predictive back animations on by default for apps that target it ([Android behaviour changes](https://developer.android.com/about/versions/16/behavior-changes-16), [predictive back guide](https://developer.android.com/guide/navigation/predictive-back-gesture)). Our app already draws edge-to-edge and sets the flag; no change needed.
- **Start-up:** Android vitals treats a cold start of **5 s or more** as excessive (warm 2 s, hot 1.5 s) ([Android: app startup time](https://developer.android.com/topic/performance/launch-time)). Our 0.5 to 0.7 s is well inside it; our own 700 ms budget is stricter than the platform's.
- **Testing:** Google's guidance combines manual testing with accessibility services, analysis tools and automated checks; automation cannot judge the quality of labels or the flow ([Android: test your app's accessibility](https://developer.android.com/training/accessibility/testing.html); Flutter docs say to test with TalkBack and VoiceOver, see [Flutter semantic roles](https://docs.flutter.dev/accessibility-and-localization/semantic-roles)). Flutter's `meetsGuideline` matchers (tap target, label, contrast) are what our suite uses; they are a floor, not a verdict.

### 3.8 Heuristics

Nielsen's ten usability heuristics remain the review frame in section 5. They are experts' rules of thumb, not tested standards.

## 4. The current build checked against these standards

Result of comparing the build with section 3. **Fail** = we know it does not meet the bar. **Gap** = not checked. **Pass** = meets it by design or automated check. Nothing here replaces a real audit.

| # | Standard | Status | Evidence / note | Action |
|---|---|---|---|---|
| S1 | 48 dp touch targets (Android); WCAG 2.5.8 24 px (AA) | Pass | `androidTapTargetGuideline` on 25 routes, light and dark, 100% and 160% | Keep |
| S2 | Gestures have single-pointer alternatives (WCAG 2.5.1) | Pass (design) | Circle tap, long-press menu, custom accessibility actions | Verify the custom actions with TalkBack |
| S3 | No dragging-only function (2.5.7) | Pass | No drag interactions in the app | Keep |
| S4 | Resize text to 200% (1.4.4) | Pass | Goldens at 200%; sweeps at 150% and 160%; **new: dark sweep of 21 routes at 200% with no layout errors** (found and fixed a Calendar cell and a button overflow) | Keep |
| S5 | Reflow at 320 px (1.4.10) | Pass, one documented exception | **New: 320 dp sweeps in light and dark at 130% text pass** (layout, labels, contrast). Tab rows now fade at the cut-off edge (U2). **Exception:** the Calendar's seven-column grid cells are 45.7 x 55 dp at 320 dp (336 needed for 48 dp each); they exceed WCAG 2.5.8's 24 px and are excluded only from the 48 dp check at widths under 336 dp | Keep the exception noted |
| S6 | Text contrast 4.5:1 (1.4.3) | Pass | `textContrastGuideline` plus palette test in both themes | Keep |
| S7 | Non-text contrast 3:1 (1.4.11) | Pass for controls; focus rings unverified | **New token `controlBorder`** (light `#857D90` 3.9:1 on cards, dark `#827A92` 4.1:1) used for text fields, search, outlined buttons, unselected chips, glance chips and the empty status circle; tested in both themes. Dividers and card edges keep the quiet `line` (they do not identify a control) | Verify keyboard focus indicators on a device with a keyboard (needs a person) |
| S8 | Undo reachable long enough (2.2.1, Material, Flutter) | Pass | **New:** the toast lasts 10 s (was 5), and with TalkBack or other accessibility navigation on it stays until Undo or a new **Dismiss** button; tested with a simulated screen reader | Check with TalkBack on the phone (U16, needs a person) |
| S9 | Status messages announced (4.1.3) | Pass (design); live-region flag now tested | A test confirms the toast's semantics node is a live region | Verify spoken output with TalkBack (needs a person) |
| S10 | Dark theme guidance | Pass | Tinted dark grey surfaces, lighter accents, body text 16:1 | Keep |
| S11 | Edge-to-edge, predictive back, start-up | Pass | Measured on device; flags set | Keep |
| S12 | Participants per test (NN/g) | **Fix the plan** | v1 asked for 5 mixed people | Section 7 revised |
| S13 | Onboarding hints (NN/g) | Pass (plan) | One contextual hint, not a tour | Test whether it is needed |

## 5. Who it is for, journeys and heuristic review

### 5.1 Assumed groups (see A1 to A7)

| Group | Assumed situation | What they need from the phone app |
|---|---|---|
| **Solo maker** | Several projects at different stages; laptop for deep work, phone between sessions | See what is due today, tick things off, capture a task in seconds, glance at project progress |
| **Evaluator** (client, teacher, teammate) | Short attention, judges the idea quickly, any phone | Understand the idea fast, try a few real actions, see that it is coherent and polished |

Not designed for: teams, cross-device sync, tablets as the primary device.

### 5.2 Principles for UX decisions

1. **Answer "what now?" first.** 2. **One hand, thumb zone** (treated as an assumption, A3). 3. **Act where you are.** 4. **Always reversible**, confirm only when work would be lost. 5. **Say what is real.** 6. **Respect the person's settings.** 7. **Plain words.** 8. **No dead ends.** 9. **Help at the point of need, once**, not a tour (section 3.6).

### 5.3 Key journeys and where the build stands

Status is the developer's reading of the build (phone and tests), **not user evidence**. P = works as designed, ~ = works with a known weakness, X = missing.

| # | Journey | Steps today | Status | Known weakness / risk |
|---|---|---|---|---|
| J1 | First launch: understand the product, get in | Welcome → "Continue as demo user" → Home | ~ | Welcome is a long marketing page; the six-card carousel is dense (A4) |
| J2 | See what is due | Home: one headline ("2 tasks need you"), "Up now", Continue, Up next | P | Redesigned after first-impression feedback (see 5.5); untested with people |
| J3 | Complete a task | Tap the circle, or swipe right, or long-press → Mark done; Undo toast | ~ | One-time hint now explains swipe and press-and-hold (U3), untested with people (A7); toast timing fixed (S8); tile moves group with no animation |
| J4 | Reschedule | Swipe left (tomorrow), or long-press → Pick a date | ~ | Swipe left means "tomorrow" only; no cue |
| J5 | Capture a task | + → type → Add; chips; long-press +; launcher shortcut | P | Carried-over project may surprise; tip appears once |
| J6 | Find something | Search icon → type; type chips; recent searches | ~ | No match highlighting; search behind an icon |
| J7 | Check a project | Projects → project page (collapsing header, five tabs) | ~ | Tab row now fades at the cut-off edge (U2); no coverage ring or traceability timeline |
| J8 | Follow the "why" | Task or file sheet → relation chips | ~ | Chips small; "Why it exists" below the fold; no visual chain |
| J9 | Read a document | Library → reader (progress, text size, outline sheet) | P | Edit is a preview; no in-document search |
| J10 | Change how it looks | Account → theme, text size, reduce motion, week start, vibration | P | One long page |
| J11 | Recover from a mistake | Undo toast (10 s, or until dismissed with a screen reader; 20 steps), discard-draft confirmation | ~ | Only the latest action is undoable from the toast; no change list |
| J12 | Use with a screen reader | Custom actions, labels, headers | ~ | Automation only (A16) |

### 5.4 Heuristic review

| Heuristic | Observation | Sev | Proposed change |
|---|---|---|---|
| Visibility of system status | After a swipe or tap only the toast and a count change; the destination group may be out of view | M | Briefly keep the tile with a check before it moves; announce the move |
| Match with the real world | "Requirement", "Milestone", "Revision", "Deliverable" come from the website | M | One-line explainers at first use, reusing Help text (A6) |
| User control and freedom | Undo exists for tasks; project and requirement edits are previews | M | Say plainly where a change cannot be made and why |
| Consistency and standards | "High" priority is text and icon in lists and a pill in sheets | L | One component per meaning |
| Error prevention | Draft protection on Quick add, New project, editor; delete has Undo | L | Keep |
| Recognition rather than recall | Swipe and long-press are hidden | H | One contextual hint on the first tile, once, replayable from Account (3.6) |
| Flexibility and efficiency | Shortcuts, long-press +, typed syntax, chips | L | Keep; add shortcut hints to Help |
| Aesthetic and minimalist design | Lighter tiles; Home still has seven sections | M | Test whether "Up next" and "Recent" both earn their place |
| Help users recover from errors | Designed error states; real errors cannot occur (no network) | L | Keep for the future |
| Help and documentation | Guide bundled in Help; predates swipe, undo, settings | M | Update the guide |

### 5.5 First-impression feedback: too much at once, no visual hierarchy (2026-11-15)

**Source:** the owner, looking at the app on the phone: "the amount of info on the screen at once and no visual hierarchy, nothing guides where to look". One person's reaction, but it is the first impression, so it was acted on at once. It matches the heuristic "aesthetic and minimalist design" (section 5.4) and the earlier note that Home had seven sections.

**What was wrong (read from the screenshots):** Home showed about 30 separate pieces in the first screen: the logo bar, a "Home" title and subtitle, four boxes of figures, three tiles each carrying project, milestone, due pill, priority, a progress ring and sometimes "Blocked", a card, a carousel, a list and a recent list. Every piece had a similar size, weight and colour (pink, yellow, blue, red all in use), so nothing led. Tasks had three bordered boxes (search, filter, add) plus a tip before the first task.

**Principles applied:** one focal point per screen; size and weight carry the order (headline, then section labels, then content, then meta); colour is for exceptions (overdue is the only coloured due date; blocked is the only other alert); fewer, more important things above the fold; everything else quiet or moved.

**Changes (U18, done 2026-11-15):**
- **Home:** the "Home" title, subtitle and four figure boxes became one date line, one headline sentence ("2 tasks need you", red when anything is overdue) and one line of figures; the headline opens Tasks. Below it: Up now (three tiles), Continue (one project), Up next (three quiet rows) and a "See insights" link. Removed: the project carousel and the Recent list (Projects and Search cover them).
- **Task tile:** from four lines and a right-hand stack to two lines: the title and when it is due, then one quiet line (project, High, subtask count, Blocked). Milestone and the progress ring moved to the detail sheet. Today is bold, "in 4 days" is muted, only overdue is coloured.
- **Tasks:** the inline "Add a task" box is the only box on Today (search and filters stay on Upcoming, Calendar and All; the app bar Search finds tasks anywhere); the helper line under it was removed (the tip explains it once).
- **Section labels** are one quiet style, with spacing between groups larger than spacing inside them.

**Test:** one test checks that the headline is clearly larger than a section label and that the removed repeats stay removed. **Untested with people:** add to session task 2 ("Find what you should do first today") a question after it: "Where did your eye go first?" and compare Home with and without the headline if time allows. Risk: the headline may be read as an alert; watch for that.

## 6. Content and microcopy plan

- **Voice:** calm, plain, second person, short. Verbs on buttons.
- **Review list:** every Preview-only sheet (say what the real product would do and that this demo does not); empty states (one sentence of purpose, one action); the Welcome page (shorten); the typed-syntax tip; Help sections on gestures, undo and settings.
- **Dates:** "Today", "Tomorrow", weekday names within a week, else "14 Nov"; readable by a screen reader.
- **Terms:** consistent website vocabulary; short glossary in Help; info sheets at first contact (Specs, "Why it exists").
- **Localisation:** English only; dates and 24 h time follow the device where a picker is used.

## 7. Research plan

### 7.1 Participants (revised from v1)

Following the NN/g rule (section 3.4): the two groups are distinct, so **3 to 4 people per group per round**, and **two rounds**, with fixes between them.

| Round | Solo makers | Evaluators | Assistive technology / large text | Total |
|---|---|---|---|---|
| 1 | 3 to 4 | 3 to 4 | 1 (screen reader or 200% text user, run the same script) | 7 to 9 |
| 2 (after fixes) | 3 | 3 | 1 | 7 |

- **Not** the developer, and not people who have already used the app.
- Include at least one person with a **small phone** and one with a **large phone**; at least one iPhone owner is useful for questions about A11 but cannot test the Android build.
- Results are **qualitative**. Do not report percentages as if they were statistics. A quantitative claim needs about 20 people (section 3.4).
- **Before the sessions (R1):** a 10-minute interview per participant about their own work: how they plan the day, what tool they use, what they do on the phone. This tests A1, A2, A5.

### 7.2 Sessions

- **How:** in person or video, on their own phone if possible (sideload the release APK), otherwise the test phone. 30 minutes each, think-aloud, one facilitator and one note-taker. Phone held one-handed for the capture tasks.
- **Consent and privacy:** say nothing is stored by the app; take notes by hand or in a document; screen recordings only with consent and deleted after analysis; no personal data in the app.
- **Tasks:**

| # | Task | Success | Watch for |
|---|---|---|---|
| 1 | "Open the app. In your own words, what is it for?" | Names task or project management | Skips or reads Welcome; first tap |
| 2 | "Find what you should do first today." | Points at Up now or Today within 10 s | Stat chips, scrolling, wrong tab |
| 3 | "Mark that done. Now undo it." | Completes and undoes unaided | Which gesture first; whether the toast is noticed in time |
| 4 | "Move another task to tomorrow." | Swipe or menu | Discovery of swipe; fear of losing the task |
| 5 | "Add three tasks: one for Project Garden tomorrow, one high priority, one with no details." | All three correct | Chips vs typed syntax; carried-over project |
| 6 | "Which requirement does 'Review opening scene notes' come from? Which file?" | Finds both | Relation chips; "Why it exists" |
| 7 | "Open the Opening brief and jump to 'Open questions'." | Uses Outline | Whether the button is noticed |
| 8 | "Make the text bigger and switch to dark mode." | Finds Account settings | Path; time |
| 9 | "Is anything you did saved?" | Says it resets | Wrong beliefs about saving |

- **Measures per task:** unaided / with a hint / failed; time; errors; one quote; the **single ease question** (1 to 7). After the session: what was easy, what was confusing, what would you change first. The SUS questionnaire is optional and not reported as a score with fewer than about 20 people.
- **Reference points, not targets to chase:** SEQ averages about 5.5 across tasks in the literature (3.4). Our own aims from [PLAN-MOBILE-UI.md](PLAN-MOBILE-UI.md): complete a task in one gesture; add a task with project and date in two taps beyond typing; find an overdue task within one screen of app open.
- **Analysis:** list every problem with the task, evidence (who, what happened), severity (H/M/L) and proposed fix; fix all H and the cheap M before round 2.

### 7.3 Assistive technology walkthrough (TalkBack)

Run on the phone with TalkBack on, eyes off the screen where possible. Android's guidance is that automation cannot judge label quality or flow, so this is a real test.

1. Open, sign in as the demo user, reach Home. Titles and landmarks make sense.
2. Home: chips announce value and that they are buttons.
3. A task tile: title, project, status, due date; the actions menu shows Mark done, Move to tomorrow, Mark blocked, More actions, Delete, and each works; the Undo message is announced (WCAG 4.1.3) and **stays long enough to reach** (S8).
4. Quick add: fields, chips and buttons announced with values; the date picker is usable.
5. Tasks tabs, project tabs, the reader's Outline sheet, Settings switches.
6. Display size, bold text and 200% text on; nothing clipped or hidden.
7. Record pass or fail per step with the exact announcement for any failure.

### 7.4 Device and context checks

- Phones: one low-end (done: A05s), one small (320 to 360 dp), one large; a tablet or the emulator in landscape.
- One-handed reach with the right and left thumb.
- Light theme outdoors, dark theme at night.
- Interruptions: rotate, background, restore.

## 8. Accessibility acceptance

Keep green (automated): tap target size, labelled targets and text contrast on every route in both themes at 100% and 160%; 200% goldens; reduced motion.

Add: 320 dp width sweep (S5); 200% dark sweep (S4); a non-text contrast check for borders, focus and selected states (S7, U13); the TalkBack pass (7.3); Switch Access can reach every action; no information by colour alone; focus order follows reading order.

## 9. Prioritised backlog

Effort: S under a day, M a few days, L a week or more. **Do not start M or L items before round 1 of the sessions, except where marked.** New in v2 are U13 to U17.

| # | Item | Why | Effort | Gate | Status |
|---|---|---|---|---|---|
| U1 | Run round 1 of the sessions and the TalkBack walkthrough | Everything else is a guess without them | M | First |
| U14 | **Undo toast: stay until acted on or dismissed when an action is present, or at least 10 s, and never auto-dismiss while a screen reader is on** | S8: fails the current platform behaviour and WCAG 2.2.1 argument | S | May do now | **Done 2026-11-15.** 10 s, persistent with a screen reader, Dismiss button; 3 tests |
| U2 | Show that tabs scroll sideways (edge fade) or shorten labels so none are cut off at 320 to 360 dp | S5, J7 | S | May do now | **Done 2026-11-15.** Edge fade on `ViewTabs` that tracks scroll position; 1 test |
| U13 | Raise the contrast of field, chip and selected-state borders to 3:1 (keep subtle dividers), check focus indicators | S7 | S to M | May do now | **Done 2026-11-15.** `controlBorder` token; 4 tests (both themes, Material outline) |
| U15 | Add a 320 dp width sweep and a 200% dark sweep to the tests | S4, S5 | S | May do now | **Done 2026-11-15.** 320 dp light and dark, 200% dark; found and fixed 2 overflows |
| U3 | One contextual hint for swipe and long-press on the first task tile, once, dismissible, replayable from Account; **no tour** | Recognition over recall; NN/g on tutorials | S | May do now | **Done 2026-11-15.** One tip on Today, dismissible, **Show tips again** in Account; 1 test |
| U4 | Rewrite every Preview-only message and update the Help guide for swipe, undo and settings | G6; guide predates them | S | May do now | **Done 2026-11-15.** 14 specific messages, scrollable sheet, bundled guide rewritten for swipe, undo, settings; 3 tests |
| U16 | Verify custom accessibility actions, live-region announcements and Undo timing with TalkBack and record the exact announcements | S2, S9 | S | With U1 |
| U17 | Add long-title and many-project cases to the data used in tests (A10) | Sample data hides real-world problems | S | May do now | **Done 2026-11-15.** Long names and titles are covered by the 320 dp and 200% sweeps and the 500-task test; the sample data itself was not changed |
| U5 | Home: replace the "Home" header block with a person-relevant title and date; test removing "Recent" or "Up next" | Answer "what now" higher | S | After round 1 |
| U6 | Keep a completed tile visible briefly (check, then move) and announce the move | System status | M | After round 1 |
| U7 | "Why it exists / What it becomes" as a visible chain (coverage ring, traceability timeline) | G3 | L | After round 1 |
| U8 | In-list search on Home and Tasks; match highlighting in Search | Faster finding | M | After round 1 |
| U9 | Welcome as a three-step onboarding with Skip, shown once per session | First-run clarity | M | After round 1 |
| U10 | Swipeable tab views for Tasks and project tabs | Native feel | M | After round 1 |
| U11 | A "recent changes" list (the undo history made visible) | Control and trust | M | After round 1 |
| U18 | **First-impression hierarchy and density on Home and Tasks (section 5.5)** | Owner feedback: too much at once, nothing guides the eye | M | Owner request | **Done 2026-11-15.** Headline-led Home, two-line tiles, one box on Today; 1 new test, 9 updated |
| U12 | Empty and error illustrations | Delight, clarity | M | Low priority |

## 10. Measures and how often

These are indicators for decisions, not statistics (small samples).

| Measure | Source | Reference |
|---|---|---|
| Unaided success on tasks 2, 3, 5 | Sessions | Most participants in each group; any task that fails for two or more people is a priority |
| Single ease question per task | Sessions | About 5.5 average in the literature; look at tasks well below the rest |
| Time to complete a task from app open | Sessions | Note, compare between rounds |
| Wrong beliefs about saving | Task 9 | Aim for none |
| Accessibility guidelines | Automated suite | Stay green in both themes at 100%, 160%, 200% and at 320 dp |
| TalkBack walkthrough | Manual | All steps pass |
| Cold start and scroll smoothness | Device | Stay under our budgets (700 ms, no frame over 25 ms); the platform's own cold-start limit is 5 s |

Record each round in `LOG.md`: date, version, who (groups only, no names), what was found, top three problems, what changed.

## 11. Decisions needed

| # | Decision | Recommendation |
|---|---|---|
| X1 | Who are the participants and how are they recruited? | Owner names them; fellow makers and classmates are better than friends who know the project; nobody who has seen the app |
| X2 | May sessions be screen-recorded? | Optional, with consent, delete after analysis |
| X3 | Keep the Welcome marketing page or replace it with a short onboarding (U9)? | Decide after round 1, from task 1 |
| X4 | Title "Home" or "Today" with the date? | Test both in round 1 |
| X5 | Is a single contextual hint acceptable, given the calm tone? | Yes if once, dismissible, replayable |
| X6 | What bar applies: WCAG 2.2 AA as the reference, or only Android's own guidance? | Use WCAG 2.2 AA as the reference for review; do not claim conformance without an audit |
| X7 | Should the Undo toast persist when an action is present, as Flutter's own default now does? | Yes (U14) |

## 12. Risks

| Risk | Mitigation |
|---|---|
| Small sample misses problems; groups differ | Two rounds, 3 to 4 per group, retest after fixes (NN/g) |
| People judge the demo as a finished product and are frustrated by previews | Say it is a demo up front; U4 makes previews specific; task 9 checks beliefs |
| Redesigning from assumptions | The Gate column: nothing larger than S before round 1; the assumptions register (section 2) shows what is untested |
| Accessibility regressions while iterating | Automated suite in both themes at 160%, plus 200% and 320 dp (U15) |
| Claiming compliance that was not audited | Say "checked against" and list gaps (section 4); never "conformant" |
| Test phone differs from participants' phones | Use theirs when possible; one small, one large |
| Over-explaining clutters a calm UI | One hint, once; measure whether people need it |
| Secondary sources misquote standards | Section 3 marks what was read at the source and what was not; verify against W3C and developer.android.com before quoting |

## 13. Next steps

1. Owner answers X1, X2 and X6; schedule round 1 (7 to 9 people). X7 is settled by U14 (done).
2. ~~Do the "may do now" items~~ **done 2026-11-15** (U14, U2, U13, U15, U3, U4, U17).
3. Run the TalkBack walkthrough yourself first (U16) to remove obvious blockers; print the script in 7.2. This and the sessions are the parts an assistant cannot do: they need a person with the phone.
4. Run round 1; write the findings table; fix H and cheap M; run round 2.
5. Update this file with real personas, tested assumptions (move A-numbers from U to V or disproved), findings, and the new status of each journey in 5.3.

## 14. Sources

Read at the source: [W3C Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html); [NN/g: Why you only need to test with 5 users](https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/); [Flutter: SnackBar with action behaviour change](https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update).

From search summaries (verify before quoting): [W3C Understanding 2.5.1](https://www.w3.org/WAI/WCAG22/Understanding/pointer-gestures) and [2.5.7](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements); [Google Accessibility Help: touch target size](https://support.google.com/accessibility/android/answer/7101858); [Android: test your app's accessibility](https://developer.android.com/training/accessibility/testing.html); [Android: app startup time](https://developer.android.com/topic/performance/launch-time); [Android 16 behaviour changes](https://developer.android.com/about/versions/16/behavior-changes-16); [Predictive back](https://developer.android.com/guide/navigation/predictive-back-gesture); [Material dark theme (M2)](https://m2.material.io/design/color/dark-theme); [NN/g app tutorials](https://www.nngroup.com/articles/onboarding-tutorials/); [Hoober 2013, UXmatters](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php?); [MeasuringU: SEQ and SUS](https://measuringu.com/?p=170); [TetraLogical: what's new in WCAG 2.2](https://tetralogical.com/blog/2023/10/05/whats-new-wcag-2.2); [Yatil: Resize Text and Reflow](https://www.yatil.net/blog/resize-text-reflow); [WCAG 4.1.3 overview](https://wcag.dock.codes/documentation/wcag413); [W3C WAI list on toasts and 2.2.1](https://lists.w3.org/Archives/Public/w3c-wai-ig/2025AprJun/0085.html); [Scott O'Hara: a toast to a11y toasts](https://scottohara.me/blog/2019/07/08/a-toast-to-a11y-toasts.html); [LogRocket: UX error prevention](https://blog.logrocket.com/ux-design/ux-error-prevention-examples/); [Ignore the Code: Nielsen and Norman on gestures](https://ignorethecode.net/blog/2010/05/30/nielsen_and_norman_on_gestures/); [UX Collective: discoverability](https://uxdesign.cc/discoverability-in-the-age-of-touchscreens-125fcb392e08); [Shopify: mobile onboarding](https://www.shopify.com/partners/blog/mobile-app-onboarding); [Livefront: coach marks](https://medium.com/livefront/put-me-in-coach-marks-8146c61ca875); [Flutter semantic roles](https://docs.flutter.dev/accessibility-and-localization/semantic-roles); [Android codelab: testing accessibility](https://developer.android.com/codelabs/basic-android-kotlin-compose-test-accessibility).

Not used: a blog claim of "30 to 50%" first-time gesture discovery (no source). Not found: an official Material 3 page with snackbar durations and spacing between targets; check m3.material.io directly.
