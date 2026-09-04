local source = debug.getinfo(1, "S").source:sub(2)
CONFIG_DIR = source:match("(.*/)") .. ".."
package.path = CONFIG_DIR .. "/?.lua;" .. CONFIG_DIR .. "/?/init.lua;" .. package.path

local subscriptions = {}
local items = {}
local remove_count = 0
local set_count = 0

local payload = {
  spaces = {
    {
      id = 84,
      index = 3,
      label = "space-1",
      ["has-focus"] = true,
      ["is-visible"] = true,
    },
  },
  windows = {
    {
      id = 100,
      app = "Arc",
      space = 3,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 800, h = 900 },
      ["stack-index"] = 1,
      ["has-focus"] = true,
      ["is-visible"] = true,
    },
    {
      id = 101,
      app = "Arc",
      space = 3,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 800, h = 900 },
      ["stack-index"] = 2,
      ["is-visible"] = true,
    },
  },
}

local function new_item(name, properties)
  local item = { name = name, properties = properties or {}, sets = {} }
  function item:set(properties)
    set_count = set_count + 1
    table.insert(self.sets, properties)
  end
  function item:subscribe(event, callback)
    subscriptions[event] = callback
  end
  items[name] = item
  return item
end

sbar = {}
function sbar.add(kind, name, properties, bracket_properties)
  if kind == "event" then
    return nil
  end
  return new_item(name, kind == "bracket" and bracket_properties or properties)
end
function sbar.remove()
  remove_count = remove_count + 1
end
function sbar.delay(_, callback)
  callback()
end
function sbar.exec(command, callback)
  if command:match("query%-windows%-state%.sh$") then
    callback(payload, 0)
  elseif command:match("query%-current%-window%.sh$") then
    callback(payload.windows[1], 0)
  else
    callback({}, 1)
  end
end

require("controller").setup()

assert(items["space.84.content.1"], "first reusable content slot was rendered")
assert(items["space.84.content.2"], "second reusable content slot was rendered")
assert(subscriptions.yabai_event, "custom yabai event is subscribed")
assert(items["space.84.content.1"].properties.background.drawing,
  "startup snapshot selects its focused window")
assert(items["space.84.content.2"].properties.background.color == 0x00000000,
  "unselected window gets an explicit transparent background")
assert(set_count == 0, "startup selection is part of the structural render")

subscriptions.yabai_event({ EVENT = "window_focused", WINDOW_ID = "100" })
assert(set_count == 0, "known focus keeps the existing selection")

subscriptions.yabai_event({ EVENT = "window_focused", WINDOW_ID = "100" })
assert(set_count == 0, "duplicate focus writes nothing")

subscriptions.yabai_event({ EVENT = "window_focused", WINDOW_ID = "101" })
assert(set_count == 2, "focus change clears the old item and selects the new item")

local removals_before_noop = remove_count
subscriptions.yabai_event({ EVENT = "window_moved", WINDOW_ID = "101" })
assert(remove_count == removals_before_noop, "unchanged drawing key skips structural writes")

payload.windows[2].frame = { x = 900, y = 0, w = 800, h = 900 }
payload.windows[2]["stack-index"] = 0
local removals_before_layout_change = remove_count
subscriptions.yabai_event({ EVENT = "window_resized", WINDOW_ID = "101" })
assert(remove_count == removals_before_layout_change,
  "layout group change updates reusable slots without tearing down the bar")
local moved_window_properties = items["space.84.content.3"].sets[
  #items["space.84.content.3"].sets
]
assert(moved_window_properties.icon.drawing == true,
  "window moved into a hidden slot turns its icon drawing back on")
assert(moved_window_properties.icon.align == "center",
  "window moved into a hidden slot restores icon alignment")

table.remove(payload.windows, 1)
local removals_before_change = remove_count
subscriptions.yabai_event({ EVENT = "window_destroyed", WINDOW_ID = "100" })
assert(remove_count == removals_before_change,
  "window removal updates reusable slots without tearing down the bar")
assert(items["space.84.content.2"].sets[#items["space.84.content.2"].sets].drawing == false,
  "unused content slot is hidden in place")

print("controller_spec: ok")
