# couch-tv on an Apple Watch

Volume, playback and "Ask" (the Claude assistant) from your wrist, with Apple's Shortcuts app. Nothing
to install and no developer account: two shortcuts you make once on the iPhone, which then show up
on the watch. Option B only (it talks to the bridge).

It works at home: the watch must be on the home Wi-Fi, or near your iPhone while the iPhone is on
the home Wi-Fi. Like the phone remote, anyone on the Wi-Fi can use it.

You need the bridge's address, the one the phone remote opens, for example
`http://192.168.1.20:5400`. Below it is written as `<bridge>`.

## 1. "TV Remote": volume and playback

On the iPhone, open **Shortcuts**, tap **+**, and name it **TV Remote**. Add these actions, in this
order (search for each by name):

1. **List**. Type one item per line: `Volume up`, `Volume down`, `Mute`, `Play`, `Pause`, `Back`,
   `OK`, `Power`.
2. **Repeat**. Set it to 50 times. Drag the next two actions inside it.
3. **Choose from List**. Its list is the List from step 1.
4. **Get Contents of URL**. URL: `<bridge>/api/watch`. Tap the arrow to show more:
   - Method: **POST**
   - Request Body: **JSON**. Add a field, type **Text**, key `do`, value: the **Chosen Item**
     variable (tap the value, then pick Chosen Item above the keyboard).

Tap the **(i)** at the bottom and switch on **Show on Apple Watch**.

On the watch, open it and tap a button. The list comes back after each tap, so you can press
Volume up three times in a row. Each Volume up or Volume down is 3 steps. Press the crown or swipe back
to close it.

## 1b. "TV Volume": turn the crown

Turning the Digital Crown scrolls a Shortcuts list, so a list of volume levels gives you crown
control: turn to the level, tap it, and the TV goes straight there.

New shortcut, named **TV Volume**:

1. **List**, one level per line: `0`, `4`, `6`, `8`, `10`, `12`, `14`, `16`, `18`, `20`, `22`,
   `25`, `30`, `35`, `40`. (Pick the levels you actually use. Most rooms live between 8 and 25.)
2. **Repeat**, 50 times, with the next two inside it.
3. **Choose from List**, from that List. Prompt: `Volume`.
4. **Get Contents of URL**, `<bridge>/api/watch`, **POST**, Request Body **JSON**, Text field `do`
   with the **Chosen Item** variable.

**Show on Apple Watch** on. Open it, turn the crown, tap a level, and the list comes back for the next change.
Close it with the crown press or swipe back. Siri works too: "Hey Siri, TV Volume".

## 2. "Ask the TV": talk to the Claude assistant

New shortcut, named **Ask the TV**:

1. **Dictate Text**. Stop listening: **After Pause**.
2. **Get Contents of URL**. URL: `<bridge>/api/watch`, Method **POST**, Request Body **JSON**, two
   Text fields:
   - `do`, with the value `ask`
   - `text`, with the value: the **Dictated Text** variable
3. **Show Result**, showing **Contents of URL**. (Or **Speak Text** to hear the answer instead.)

Switch on **Show on Apple Watch** as before.

Say what you want, the way you would in the phone's Ask box: "put on a romcom for the two of us",
"turn it down a bit", "open YouTube". The reply shows on the watch, usually within 10 to 30
seconds.

## 3. Make them quick to reach

- **Siri:** "Hey Siri, Ask the TV" or "Hey Siri, TV Remote".
- **Apple Watch Ultra: the Action button.** On the watch, Settings, Action Button, Shortcut, pick
  **Ask the TV**. One press, then talk.
- **Watch face:** touch and hold the face, Edit, and pick Shortcuts for a complication.
- **One-tap extras (optional):** a shortcut with only step 4 of "TV Remote" and a fixed value
  (`Volume up`, `Pause`) makes "Hey Siri, TV louder" work without the list.

The first time, the watch or the iPhone may ask to allow Shortcuts to connect to the bridge's
address: tap **Allow**.

## The watch app (real crown control)

`watch/` is a small Apple Watch app: turn the crown and the volume follows as you turn, tap the dial
to mute, Back, Play and Pause below it, and an Ask button that takes your voice. The ⋯ button has the
arrows, OK, Home, Power and the bridge's address.

Apple only builds watch apps on a Mac, so this repository builds it on GitHub's Macs instead
(`.github/workflows/watch.yml`). Every push builds it for the watch simulator, which needs no Apple account.
Getting it onto your own watch goes through TestFlight, and that needs a paid **Apple Developer Program**
membership (US$99 a year). Once, in this order:

1. **Join the Apple Developer Program** with your Apple ID: developer.apple.com/programs/enroll. Approval can
   take up to two days. Then note your **Team ID** (developer.apple.com/account, Membership details).
2. **Register the app's id.** developer.apple.com/account, Certificates, Identifiers and Profiles,
   Identifiers, **+**, App IDs, App. Description `Couch TV Watch`, Bundle ID **Explicit**, for example
   `com.yourname.couchtv.watch`. No capabilities needed. Continue, Register.
3. **Make the app in App Store Connect.** appstoreconnect.apple.com, Apps, **+**, New App. Platform **iOS**
   (watch-only apps live there), a name nobody else uses on the App Store (for example
   `Couch TV Watch Yourname`), the bundle id from step 2, any SKU, Full Access. It is never published:
   TestFlight is private to you.
4. **Make an API key for the build.** App Store Connect, Users and Access, Integrations, App Store Connect API,
   Team Keys, **+**. Name `couch-tv watch build`, access **Admin** (it lets the build make its own
   signing certificate). Download the `.p8` file (Apple lets you download it only once) and note the
   **Key ID** and the **Issuer ID** shown above the list.
5. **Give the key to your fork, yourself.** In a terminal, with `gh` signed in (each command asks you to
   paste the value, or reads the file):

   ```
   gh secret set ASC_KEY_ID -R <you>/couch-tv
   gh secret set ASC_ISSUER_ID -R <you>/couch-tv
   Get-Content "$HOME\Downloads\AuthKey_XXXXXXXXXX.p8" -Raw | gh secret set ASC_KEY_P8 -R <you>/couch-tv
   gh variable set APPLE_TEAM_ID -R <you>/couch-tv --body "<Team ID>"
   gh variable set WATCH_BUNDLE_ID -R <you>/couch-tv --body "com.yourname.couchtv.watch"
   gh variable set BRIDGE_URL -R <you>/couch-tv --body "http://<bridge address>:5400"
   ```

   (On a Mac or Linux: `gh secret set ASC_KEY_P8 -R <you>/couch-tv < ~/Downloads/AuthKey_XXXXXXXXXX.p8`.)
   Secrets are never shown again, not even to you, and never appear in the build's log.
6. **Build and upload.** GitHub, your fork, Actions, **watch app**, Run workflow, tick
   **Sign and upload to TestFlight**. About ten minutes, then Apple takes 10 to 30 minutes to process it.
7. **Install it.** App Store Connect, your app, TestFlight, Internal Testing, **+**, add yourself. On the
   iPhone, install **TestFlight** from the App Store and accept the invite; Couch TV installs on the
   watch. A TestFlight build lasts 90 days: run step 6 again for a fresh one.

## What the watch can send

`POST /api/watch` with JSON `{"do": "..."}`. Case, spaces and punctuation are ignored. The answer is a few
words of plain text (`Volume 14`, `Paused`, `TV on`), or Claude's reply.

| `do` | What it does |
| --- | --- |
| `Volume up`, `Volume down` | 3 steps louder or quieter |
| `Volume 20`, or just `20` | Straight to that level (0 to 100) |
| `Mute` | Mute on or off |
| `Play`, `Pause`, `Play pause`, `Stop`, `Rewind`, `Forward` | Playback keys (LG has no play/pause toggle: use Play and Pause) |
| `Back`, `OK`, `Home`, `Up`, `Down`, `Left`, `Right` | Remote keys |
| `Power`, `TV on`, `TV off` | Power (`Power` turns it on when it is off) |
| `ask` with `"text": "..."` | The Claude assistant (needs `ask.enabled`) |
