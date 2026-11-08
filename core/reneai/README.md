# RENEAI Offline Knowledge & Intent Guide

RENEAI Support runs 100% offline inside RENEarn Studio. You can add new answers or modify existing behavior in under 1 minute without writing code!

---

## 1. How to Add a New Smalltalk / Conversational Intent
Open `smalltalk.json` and add a new block to the `"intents"` list:

```json
{
  "id": "my_new_intent",
  "triggers": [
    "who is your favorite character",
    "favorite plant",
    "sino paborito mo"
  ],
  "replies": {
    "en": [
      "🌻 My all-time favorite is the Sunflower! Producing sun and spreading positive vibes on stream!",
      "🧟‍♂️ Definitely the Gargantuar—huge hype whenever a viewer spawns one on stream!"
    ],
    "tl": [
      "🌻 Sunflower syempre! Nagbibigay ng liwanag at tuwa sa bawat live stream!"
    ]
  },
  "chips": ["Supported games", "Link TikTok gifts to spawns"]
}
```

---

## 2. How to Add a New Q&A Article / Guide
Open `knowledge.json` and add a new entry to `"articles"`:

```json
{
  "id": "custom_macro",
  "title": "Custom Keyboard Macro Calibration",
  "keywords": ["macro", "keybind", "hotkey", "press key", "keys"],
  "answer_en": "### ⌨️ How to Configure Keyboard Hotkeys:\n\n1. Go to the **Gift Commands** tab.\n2. Click **+ Add Command** on any trigger.\n3. Select **Keyboard Hotkey** and press the key you want RENEarn to press in-game.",
  "answer_tl": "### ⌨️ Paano Mag-set ng Hotkeys:\n\n1. Pumunta sa **Gift Commands** tab.\n2. Pindutin ang **+ Add Command**.\n3. Piliin ang **Keyboard Hotkey** at itakda ang nais mong pindutin sa laro.",
  "related_ids": ["gift_mapping", "troubleshooting"]
}
```

---

## 3. How to Add Synonyms
Open `synonyms.json` and append terms to existing lists or add new groups. Words in these groups are treated as equivalents by the BM25 search engine!

