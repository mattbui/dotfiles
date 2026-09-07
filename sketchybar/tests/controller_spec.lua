local source = debug.getinfo(1, "S").source:sub(2)
CONFIG_DIR = source:match("(.*/)") .. ".."
package.path = CONFIG_DIR .. "/?.lua;" .. CONFIG_DIR .. "/?/init.lua;" .. package.path

local subscriptions = {}
local items = {}
local focus_commands = {}
local remove_count = 0
local set_count = 0
local query_count = 0
local defer_queries = false
local pending_queries = {}
local windows_status = 0
local space_result_override

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
  local item = {
    name = name,
    properties = properties or {},
    sets = {},
    subscriptions = {},
  }
  function item:set(properties)
    set_count = set_count + 1
    table.insert(self.sets, properties)
  end
  function item:subscribe(event, callback)
    self.subscriptions[event] = callback
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
local function copy(value)
  if type(value) ~= "table" then
    return value
  end
  local result = {}
  for key, entry in pairs(value) do
    result[key] = copy(entry)
  end
  return result
end
function sbar.exec(command, callback)
  if command:match("^yabai %-m query %-%-spaces ")
    or command:match("^yabai %-m query %-%-windows ") then
    query_count = query_count + 1
    local kind = command:match("%-%-spaces ") and "spaces" or "windows"
    local status = kind == "windows" and windows_status or 0
    local records = copy(payload[kind])
    if kind == "spaces" then
      local label = command:match(" %-%-space (space%-%d+)$")
      if label then
        records = nil
        for _, space in ipairs(payload.spaces) do
          if space.label == label then
            records = copy(space)
          end
        end
        status = records and 0 or 1
      elseif space_result_override then
        records = copy(space_result_override)
      end
    end
    if defer_queries then
      table.insert(pending_queries, { callback = callback, records = records, status = status })
    else
      callback(records, status)
    end
  elseif command:match("query%-current%-window%.sh$") then
    callback(payload.windows[1], 0)
  elseif command:match('focus%-target%.sh" %-%-keep%-mouse window [1-9][0-9]*') then
    table.insert(focus_commands, command)
    if callback then
      callback({}, 0)
    end
  else
    if callback then
      callback({}, 1)
    end
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

local selected_slot = items["space.84.content.1"]
local unselected_slot = items["space.84.content.2"]
selected_slot.subscriptions["mouse.entered"]()
assert(selected_slot.sets[#selected_slot.sets].background.color == 0xe6ffffff,
  "hover leaves the selected window unchanged")
selected_slot.subscriptions["mouse.exited"]()

unselected_slot.subscriptions["mouse.entered"]()
local hover_properties = unselected_slot.sets[#unselected_slot.sets]
assert(hover_properties.background.color == 0x1affffff,
  "hover gives an unselected window the specified translucent capsule")
assert(hover_properties.background.height == 20,
  "hover capsule keeps the specified height")
assert(hover_properties.background.corner_radius == 10,
  "hover capsule keeps the specified corner radius")
assert(hover_properties.icon.color == 0xfff6f7fb,
  "hover keeps the unselected window icon color")
assert(hover_properties.blur_radius == 0, "hover adds no blur")
unselected_slot.subscriptions["mouse.exited"]()
assert(unselected_slot.sets[#unselected_slot.sets].background.color == 0x00000000,
  "mouse exit restores the unselected window appearance")

selected_slot.subscriptions["mouse.clicked"]({ BUTTON = "left" })
unselected_slot.subscriptions["mouse.clicked"]({ BUTTON = "right" })
assert(focus_commands[1] == '"$HOME/.config/yabai/scripts/focus-target.sh" --keep-mouse window 100 3 true',
  "left click focuses a selected slot in case cached focus is stale")
assert(#focus_commands == 1, "non-left clicks do not run yabai")
unselected_slot.subscriptions["mouse.clicked"]({ BUTTON = "left" })
assert(focus_commands[2] == '"$HOME/.config/yabai/scripts/focus-target.sh" --keep-mouse window 101 3 true',
  "left click focuses the slot's current window ID")
-- Space visibility can change without an icon diff; clicks must still use the new value.
payload.spaces[1]["is-visible"] = false
subscriptions.yabai_event({ EVENT = "window_moved" })
selected_slot.subscriptions["mouse.clicked"]({ BUTTON = "left" })
assert(focus_commands[3] == '"$HOME/.config/yabai/scripts/focus-target.sh" --keep-mouse window 100 3 false',
  "click passes updated space visibility without rebuilding the scene")
payload.spaces[1]["is-visible"] = true
subscriptions.yabai_event({ EVENT = "window_moved" })
set_count = 0

subscriptions.yabai_event({ EVENT = "window_focused", WINDOW_ID = "100" })
assert(set_count == 0, "known focus keeps the existing selection")

subscriptions.yabai_event({ EVENT = "window_focused", WINDOW_ID = "100" })
assert(set_count == 0, "duplicate focus writes nothing")

subscriptions.yabai_event({ EVENT = "window_focused", WINDOW_ID = "101" })
assert(set_count == 2, "focus change clears the old item and selects the new item")

local removals_before_noop = remove_count
subscriptions.yabai_event({ EVENT = "window_moved", WINDOW_ID = "101" })
assert(remove_count == removals_before_noop, "unchanged drawing key skips structural writes")

local writes_before_switch = set_count
local queries_before_switch = query_count
payload.spaces[1]["is-visible"] = false
for _, window in ipairs(payload.windows) do
  window["is-visible"] = false
end
subscriptions.yabai_event({ EVENT = "layout_completed" })
assert(query_count == queries_before_switch + 2, "normal snapshot uses exactly two CLI queries")
assert(set_count == writes_before_switch, "switching away preserves known window icons")
assert(remove_count == removals_before_noop, "space switching does not rebuild the bar")
payload.spaces[1]["is-visible"] = true
for _, window in ipairs(payload.windows) do
  window["is-visible"] = true
end

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

local focus_count_before_stale_click = #focus_commands
items["space.84.content.2"].subscriptions["mouse.clicked"]({ BUTTON = "left" })
assert(#focus_commands == focus_count_before_stale_click,
  "a slot changed into a separator cannot focus its previous window ID")

table.remove(payload.windows, 1)
local removals_before_change = remove_count
subscriptions.yabai_event({ EVENT = "window_destroyed", WINDOW_ID = "100" })
assert(remove_count == removals_before_change,
  "window removal updates reusable slots without tearing down the bar")
assert(items["space.84.content.2"].sets[#items["space.84.content.2"].sets].drawing == false,
  "unused content slot is hidden in place")

-- Both requests start before either completes. Windows may finish first.
defer_queries = true
payload.windows[1]["is-visible"] = false
local writes_before_queries = set_count
subscriptions.yabai_event({ EVENT = "layout_completed" })
assert(#pending_queries == 2, "both CLI commands launch without waiting for a callback")
local function deliver(query)
  query.callback(query.records, query.status)
end
deliver(pending_queries[2])
assert(set_count == writes_before_queries, "a windows result alone cannot render")
deliver(pending_queries[1])
assert(items["space.84.content.1"].sets[#items["space.84.content.1"].sets].drawing == false,
  "normalizing the joined results removes an invisible window")
pending_queries = {}

-- Cached false survives leaving and returning to the space.
defer_queries = false
local writes_after_removal = set_count
payload.spaces[1]["is-visible"] = false
subscriptions.yabai_event({ EVENT = "layout_completed" })
payload.spaces[1]["is-visible"] = true
subscriptions.yabai_event({ EVENT = "layout_completed" })
assert(set_count == writes_after_removal, "space switches cannot resurrect an invisible window")

-- The opposite callback order also waits for the complete pair.
defer_queries = true
payload.windows[1]["is-visible"] = true
subscriptions.yabai_event({ EVENT = "layout_completed" })
deliver(pending_queries[1])
assert(set_count == writes_after_removal, "a spaces result alone cannot render")
deliver(pending_queries[2])
assert(items["space.84.content.1"].sets[#items["space.84.content.1"].sets].drawing == true,
  "showing a window again restores its icon")
pending_queries = {}

-- Old partial results must not combine with a newer request's results.
payload.windows[1]["is-visible"] = false
local writes_before_stale = set_count
subscriptions.yabai_event({ EVENT = "layout_completed" })
local old_pair = pending_queries
pending_queries = {}
deliver(old_pair[1])
payload.windows[1]["is-visible"] = true
subscriptions.yabai_event({ EVENT = "space_changed" })
assert(#pending_queries == 2, "new revision starts a separate query pair")
deliver(pending_queries[2])
deliver(old_pair[2])
assert(set_count == writes_before_stale, "stale partner cannot complete the newer pair")
deliver(pending_queries[1])
assert(set_count == writes_before_stale, "superseded invisible result cannot remove the icon")
pending_queries = {}

-- Failed pairs keep the old scene and retry both queries, up to three attempts.
defer_queries = false
windows_status = 1
payload.windows[1]["is-visible"] = false
local queries_before_failure = query_count
subscriptions.yabai_event({ EVENT = "layout_completed" })
assert(set_count == writes_before_stale, "failed query cannot apply a partial scene")
assert(query_count == queries_before_failure + 6, "three failed attempts each query both domains")
windows_status = 0
payload.windows[1]["is-visible"] = true

-- Preserve the old labelled-space fallback without a Bash wrapper.
space_result_override = copy(payload.spaces[1])
subscriptions.yabai_event({ EVENT = "layout_completed" })
assert(set_count == writes_before_stale, "label fallback preserves the same scene")
space_result_override = nil

print("controller_spec: ok")
