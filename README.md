# NavigationExtension

Typewriter extension for storing player destinations in memory (for custom commands + road network path streams).

## Build

From the Typewriter `extensions/` directory (with this module checked out at `extensions/NavigationExtension`):

```bash
./gradlew :NavigationExtension:build
./gradlew :NavigationExtension:buildAndMove
```

## Dev server (Paper 26.2)

Scripts live in `scripts/` and expect this repo at `extensions/NavigationExtension` inside a Typewriter checkout:

```bash
./scripts/dev-server.sh          # build Typewriter + extensions, start Paper
./scripts/dev-server.sh build    # build/copy plugins only
./scripts/dev-server.sh run      # start server (skip build)
```

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

1. Create a `Custom Command` entry (e.g. `findlocation_paladin`).
2. Add a `Position Argument` (world + x y z yaw pitch).
3. Add a trigger: `Set Stored Destination`.
   - `destination`: your `Stored Destination Variable` entry.
   - `position`: `Interaction Context Variable` → `Position Argument` entry, key `POSITION`.

### `cancelpath` command

Add `Clear Stored Destination` pointing at the same `Stored Destination Variable` entry.

### Road network path stream

Set `Direct Location Path Stream.targetLocation` to the same `Stored Destination Variable`.

Destinations are stored in-memory per player and reset on server restart or Typewriter reload.

## Repository layout

This extension is maintained as its **own git repository**, linked into Typewriter via a submodule at `extensions/NavigationExtension`. That keeps extension history separate from upstream Typewriter, so pulling Typewriter `develop` does not conflict with extension files.
