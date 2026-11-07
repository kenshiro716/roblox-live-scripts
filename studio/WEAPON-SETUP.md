# Weapon runtime changes

Server combat sources run through GitHubLiveLoader. Control-Control uses only the existing ControlRework effect modules.

## One-time Studio changes

Publish the current Studio place once to include the Control-Control MovesetTemplates client config, the repaired StarterPack Triple Dark Blade bridge, and the two patched ControlRework client effects backed up here. GitHub cannot replace LocalScript or ModuleScript client source at runtime.

## Controls

- Z hold opens a room. Inside it, tap Z to swap Dagger/Fist; hold Z to close. Outside an existing room, tap Z to move it.
- X/C/V/F and M1 are handled on the server. V requires the room. Hold V with a full Maximum Output meter for the cutscene attack.
- Fist M1 creates a terrain cube; the next M1 throws it. F swaps a valid unanchored target or teleports to a bounded position.

The damage, mastery, cooldowns, room size and duration are configurable in sources/Items/Control-Control/Data.lua. These values are this game's configuration; they are not verified official Blox Fruits balance values.

Client FX/animation assets are the existing game's ControlRework assets. Full environment destruction and every official visual detail are not reproduced by the server implementation.
