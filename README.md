# NavigationExtension

Typewriter extension for storing player destinations in memory (for custom commands + road network path streams).

## Build

From the Typewriter `extensions/` directory (with this module checked out at `extensions/NavigationExtension`):

```bash
./gradlew :NavigationExtension:build
./gradlew :NavigationExtension:buildAndMove
```

## Dev server (Paper 26.2)

Scripts in `scripts/` expect this repo at `extensions/NavigationExtension` inside a Typewriter checkout.

The dev server builds the **local** Typewriter engine from `settings.toml` (0.9.0) so extension versions match. Web panel static files are copied from a published Typewriter build into the local plugin JAR (panel only — not the engine version).

```bash
./scripts/dev-server.sh          # build Typewriter 0.9.0 + extensions, start Paper
./scripts/dev-server.sh build    # build/copy plugins only
./scripts/dev-server.sh run      # start server (skip build)
```

Use `DEV_SKIP_PANEL=1` if you only need in-game testing without `/connect`.

One-time submodule registration (after pushing this repo to GitHub):

```bash
./scripts/setup-navigation-submodule.sh https://github.com/<you>/NavigationExtension.git
```

## Wiring in Typewriter

Entries provided:

- `Stored Destination Variable` (`stored_destination_variable`)
- `Set Stored Destination` (`set_stored_destination`)
- `Clear Stored Destination` (`clear_stored_destination`)

### `findlocation` command

1. Create a `Custom Command` entry (e.g. `findlocation`).
2. Under that command, add a child **Position Argument** entry (not a sibling on another page).
3. On the **Position Argument** entry’s **triggers** (not the custom command’s triggers), add:
   - **Set Stored Destination**
   - Any fact modifiers (e.g. set `is_navigating` to 1)

   **Important:** triggers must live on the **argument** entry. If they are only on the custom command, `/findlocation` with coordinates fails with a usage error because Brigadier runs actions on the argument node after parsing.

4. Configure **Set Stored Destination**:
   - `destination`: your **Stored Destination Variable** entry.
   - `position`: click the green **`{ }`** on `position` and pick **Interaction Context Variable**. Then configure:
     - **Entry**: your **Position Argument** child of this command.
     - **Key**: `POSITION` (not `COORDINATE` or `VECTOR`).

   **Sanity check:** if `position` shows X/Y/Z number fields, it is still a literal position (always stores 0,0,0 with an empty world). It must show as a **variable reference** (`{ }` icon), not a position picker.

   After picking **Interaction Context Variable**, you must still configure the variable **key** on **Set Stored Destination** (not only on the variable entry elsewhere):
   - Under `position`, open the variable data → **key** field (separate from **default**).
   - **Entry** → **position_argument** (child under the `findlocation` command on the manifest page).
   - **Context key** → **POSITION**.

   If you only set **default** on `findlocation_context` on the static page, or leave **key** empty, the server logs `Missing required field ref` and coordinates are not stored. Publishing from the panel often resets an empty key — verify after each publish.

**Command syntax** (Position Argument = world + x + y + z + yaw + pitch):

```text
/findlocation <world> <x> <y> <z> <yaw> <pitch>
/findlocation minecraft:overworld -571 70 -95 0 0
```

Your Paper world folder is named `world`, but `minecraft:overworld` is still valid as the dimension key in the command.

**Easier alternative** (player’s current world, no world argument): use **Coordinate Argument** instead of Position Argument, and wire **Interaction Context Variable** with key `POSITION` on that coordinate argument entry.

### Log spam before first destination

`Direct Location Path Stream` reads the stored destination continuously. Until `/findlocation` stores a real position, the variable default has `world: ""`, which can log `No world found for identifier ''` on older builds.

### Login with path errors (`is_navigating` still 1)

`is_navigating` is a **permanent fact** — it survives relog and server restarts. Stored destinations are **in-memory only** and are cleared on restart (and on relog if the server restarted).

If you end a session while navigating without `/cancelpath`, on next login:

- `is_navigating == 1` → criteria audience turns the path on
- no stored destination → path falls back to the variable default

Missing/null facts compare as **0**, not 1 — so this is not “null means true”. It is almost always a **stale fact at 1**.

Use `/cancelpath` before disconnecting, or add a join/quit hook that clears navigation when there is no stored destination.

### `cancelpath` command

`cancelpath` has no arguments, so triggers on the **Custom Command** entry are correct. Add **Clear Stored Destination** and any modifiers (e.g. set `is_navigating` to 0).

### Road network path stream

Set `Direct Location Path Stream.targetLocation` to the same `Stored Destination Variable`.

Destinations are stored in-memory per player and reset on server restart or Typewriter reload.

## Repository layout

This extension is maintained as its **own git repository**, linked into Typewriter via a submodule at `extensions/NavigationExtension`. That keeps extension history separate from upstream Typewriter, so pulling Typewriter `develop` does not conflict with extension files.
