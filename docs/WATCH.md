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
