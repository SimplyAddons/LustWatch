# Lust Watch

Lust Watch is a World of Warcraft addon that tracks and announces when players or pets use abilities like Bloodlust or Heroism in group or raid settings. Designed with performance and simplicity in mind, Lust Watch prioritizes its core functionality for reliable group announcements.

### 🚀 Early Release

This addon is in its early release stage. All feedback is welcome. If you come across any issues, please [report them](https://github.com/SimplyAddons/LustWatch/issues).

## ✨ Features

- **Language Support**: Compatible with multiple game languages for seamless functionality across regions (*\*coming soon*).
- **Comprehensive Detection**: Tracks Bloodlust/Heroism activations from players, pets, and items with similar effects.
- **Efficient Announcing System**:
  - In groups or raids with multiple players running Lust Watch, the addon selects a single announcer to prevent duplicate messages in chat.
  - By designating one announcer, all other players benefit from reduced event monitoring, enhancing their performance.
  - In raids, combat log monitoring automatically turns off after Bloodlust/Heroism is used, resuming only after combat ends to prepare for the next possible use. This optimizes performance, as it’s typically unnecessary to track Bloodlust/Heroism beyond the ability’s 10-minute cooldown, which usually outlasts most boss encounters.

## 📖 Usage

Lust Watch operates automatically in the background. If you're the designated announcer, Lust Watch will broadcast in the chat whenever Bloodlust/Heroism abilities or items are activated.

## ⚙️ Commands

You can substitute `/lw` with `/lust` or `/lustwatch` depending on your preference.

| Command      | Description                                    |
|--------------|------------------------------------------------|
| `/lw`        | Shows addon state, including announcer status. |
| `/lw on`     | Enables Lust Watch.                            |
| `/lw off`    | Disables Lust Watch.                           |
| `/lw debug`  | Toggles debug mode for troubleshooting.        |
