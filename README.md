# pan-containers

## Introduction

fuckin lit script yo

Features:
- Placement UI
- Required Item Handling
- Confirmation Dialog
- AI Cargobob Delivery
- Unique Keys
- Craftable Secondary Keys
- Container Inventory Targeting
- Basic Placement Validation

## Preview

- [YouTube](https://www.youtube.com/watch?v=CJFZYxCp7Fo)

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [ox-core](https://github.com/overextended/ox_core) / [qb-core](https://github.com/qbcore-framework/qb-core)
## Install Instructions

- Install dependencies
- Drag and drop pan-containers into your resource folder, ensure it in server.cfg
- Run SQL file to add pan-containers table to your database
- Add items to `ox_inventory/data/items.lua`:
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

##### Planned Features (maybe):
- DetCord (or similar) raiding option for police (currently police need to get the key as well as the location)
- Attaching Containers to flatbed for transport