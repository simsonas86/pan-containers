# pan-containers

An immersive storage solution utilizing container props.

## Features:
- Container Placement UI
- Placement Validation
- AI Cargobob Delivery
- Unique Key Items
- Craftable Additional Keys

## Preview

_Shout out to [MadCap](https://github.com/ThatMadCap), for the preview video!_

- [YouTube](https://www.youtube.com/watch?v=CJFZYxCp7Fo)

## Supported Frameworks

_To add additional framework compatability simply add the core event for when a player finishes loading their character into the list `@pan-containers/server/framework.lua`_

- [ox-core](https://github.com/overextended/ox_core)
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [es_extended](https://www.esx-framework.org/) (untested as of 12/09/2024)
- [qbx_core](https://www.qbox.re/) (untested as of 12/09/2024)


## Dependencies

_Before requesting support or submitting a github issue ensure that you have all dependencies and they are started before `pan-containers`_

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)

## Updating from initial release

- Run `set pan:debug true` in the server console.
  - This will enable conversion as well as a few other commands.
- Restart the script
- Run `pan-containers:convert` in the server console.
  - This will convert all the database tables to use IDs instead of previous UUIDs. Keys will not be updated and will have to be remade (command for it pending).

## Install Instructions

- Install dependencies
- Drag and drop pan-containers into your resource folder, ensure it in server.cfg
- Run SQL file to add pan-containers table to your database
- Add items to `@ox_inventory/data/items.lua`:
```lua
	["containergps"] = {
		label = "GPS Transmitter",
		weight = 100,
		stack = false,
		degrade = 20160,
		close = true,
		description = "A gps locator to call in a container drop",
		consume = 0,
		client = {
			image = 'radio_yellow.png',
		},
		server = {
			export = 'pan-containers.containergps',
		}
	},

	["containerkey"] = {
		label = "Padlock Key",
		weight = 0,
		stack = false,
		close = true,
		description = "A simple key.",
		client = {
			image = "key.png",
		},
		buttons = {
			{
				label = 'Set Waypoint',
				action = function(slot)
					TriggerEvent('pan-containers:client:markContainer', slot)
				end
			},
		},
	},

	["blankkey"] = {
		label = "Blank Key",
		weight = 1,
		stack = true,
		close = true,
		description = "A blank key, can be used to cut new keys.",
		client = {
			image = "blankkey.png",
		}
	},
```
- Add item images in `pan-containers/images` to `ox_inventory/web/images` (delete pan-containers/images folder after if you wish)
- Add `ensure pan-containers` after all of the dependencies

Languages
- Place `setr ox:locale en` inside your server.cfg
- Change the `en` to your language

## Planned Features (maybe):
- Config option to tie containers to citizen ids or equivalent
- Removing containers as a command
- DetCord (or similar) raiding option for police (currently police need to get the key as well as the location)
- Attaching Containers to flatbed for transport