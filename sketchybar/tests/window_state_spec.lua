local source = debug.getinfo(1, "S").source:sub(2)
local config_dir = source:match("(.*/)") .. ".."
package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

local state = require("window_state")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local payload = {
  spaces = {
    {
      id = 90,
      index = 5,
      label = "space-2",
      ["has-focus"] = true,
      ["is-visible"] = true,
    },
    {
      id = 84,
      index = 3,
      label = "space-1",
      ["has-focus"] = false,
      ["is-visible"] = false,
    },
    { id = 91, index = 6, label = "unlabelled", ["has-focus"] = false },
  },
  windows = {
    {
      id = 101,
      app = "Arc",
      space = 3,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 800, h = 900 },
      ["stack-index"] = 2,
      ["is-visible"] = false,
    },
    {
      id = 100,
      app = "Arc",
      space = 3,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 800, h = 900 },
      ["stack-index"] = 1,
      ["is-visible"] = false,
      ["has-focus"] = true,
    },
    {
      id = 102,
      app = "Finder",
      space = 3,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 900, y = 0, w = 800, h = 900 },
      ["stack-index"] = 0,
    },
    {
      id = 103,
      app = "Ghostty",
      space = 3,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 300, y = 300, w = 600, h = 400 },
      ["is-floating"] = true,
    },
    {
      id = 104,
      app = "Arc",
      space = 5,
      role = "AXWindow",
      subrole = "AXDialog",
      frame = { x = 0, y = 0, w = 400, h = 300 },
    },
    {
      id = 105,
      app = "Finder",
      space = 5,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 400, h = 300 },
      ["is-hidden"] = true,
    },
    {
      id = 106,
      app = "Finder",
      space = 5,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 400, h = 300 },
      ["is-sticky"] = true,
    },
    {
      id = 107,
      app = "Homerow",
      space = 5,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 100, y = 100, w = 750, h = 642 },
      ["is-visible"] = false,
    },
  },
}

local scene = state.normalize(payload)
assert_equal(#scene.spaces, 2, "only canonical space labels are drawn")
assert_equal(scene.spaces[1].number, 1, "spaces sort by label suffix")
assert_equal(scene.spaces[1].id, 84, "space identity stays on yabai id")
assert_equal(scene.focused_space_id, 90, "focused space is recorded")
assert_equal(scene.focused_window_id, "100", "eligible focused window is recorded")
assert_equal(#scene.spaces[1].groups, 3, "two tiled groups and one floating group")
assert_equal(scene.spaces[1].groups[1].windows[1].id, 100, "stack index orders stack members")
assert_equal(scene.spaces[1].groups[1].windows[2].id, 101, "duplicate apps remain separate")
assert_equal(scene.spaces[1].groups[3].windows[1].id, 103, "floating windows form the final group")
assert_equal(#scene.spaces[2].windows, 0, "dialogs, hidden, and sticky windows are excluded")
assert_equal(scene.windows_by_id["104"].eligible, false, "excluded windows remain cached")
assert_equal(scene.windows_by_id["101"].eligible, true,
  "inactive-space windows do not require is-visible")
assert_equal(scene.windows_by_id["107"].eligible, false,
  "invisible window on a visible space is excluded")

local switching_payload = {
  spaces = {
    { id = 1, index = 1, label = "space-1", ["is-visible"] = true },
  },
  windows = {
    {
      id = 201,
      app = "Arc",
      space = 1,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 0, y = 0, w = 800, h = 900 },
      ["is-visible"] = true,
    },
    {
      id = 202,
      app = "Homerow",
      space = 1,
      role = "AXWindow",
      subrole = "AXStandardWindow",
      frame = { x = 100, y = 100, w = 750, h = 642 },
      ["is-visible"] = false,
    },
  },
}

local visible_scene = state.normalize(switching_payload)
assert_equal(visible_scene.windows_by_id["201"].eligible, true,
  "visible application window is learned as visible")
assert_equal(visible_scene.windows_by_id["202"].eligible, false,
  "invisible helper window is learned as invisible")

switching_payload.spaces[1]["is-visible"] = false
switching_payload.windows[1]["is-visible"] = false
local inactive_scene = state.normalize(switching_payload, visible_scene.window_visibility)
assert_equal(inactive_scene.windows_by_id["201"].eligible, true,
  "inactive space retains the last visible application window")
assert_equal(inactive_scene.windows_by_id["202"].eligible, false,
  "inactive space retains the invisible helper exclusion")
assert_equal(inactive_scene.key, visible_scene.key,
  "space visibility changes do not alter the structural key")

-- Reproduce a switch between the spaces query and the windows query.
switching_payload.spaces[1]["is-visible"] = true
local mixed_scene = state.normalize(switching_payload, visible_scene.window_visibility)
assert_equal(mixed_scene.key, visible_scene.key,
  "mixed transition snapshot cannot erase a previously visible window")
switching_payload.spaces[1]["is-visible"] = false
local after_mixed_scene = state.normalize(switching_payload, mixed_scene.window_visibility)
assert_equal(after_mixed_scene.key, visible_scene.key,
  "mixed snapshot cannot poison the inactive-space cache")
assert_equal(after_mixed_scene.windows_by_id["202"].eligible, false,
  "helper exclusion survives mixed snapshots")

switching_payload.windows[1]["is-hidden"] = true
local hidden_scene = state.normalize(switching_payload, mixed_scene.window_visibility)
assert_equal(hidden_scene.windows_by_id["201"].eligible, false,
  "explicit hiding still removes a previously visible window")
switching_payload.windows[1]["is-hidden"] = false
switching_payload.windows[1]["is-minimized"] = true
local minimized_scene = state.normalize(switching_payload, hidden_scene.window_visibility)
assert_equal(minimized_scene.windows_by_id["201"].eligible, false,
  "explicit minimization still removes a previously visible window")
switching_payload.windows[1]["is-minimized"] = false
local restored_scene = state.normalize(switching_payload, minimized_scene.window_visibility)
assert_equal(restored_scene.key, visible_scene.key,
  "restoring a real window on an inactive space restores its icon")

local unknown_scene = state.normalize(switching_payload)
assert_equal(unknown_scene.windows_by_id["202"].eligible, true,
  "unknown inactive windows remain provisionally included")
assert_equal(unknown_scene.window_visibility["202"], nil,
  "provisional inclusion is not a visible observation")
switching_payload.spaces[1]["is-visible"] = true
local observed_scene = state.normalize(switching_payload, unknown_scene.window_visibility)
assert_equal(observed_scene.windows_by_id["202"].eligible, false,
  "first visible-space observation can still exclude an unknown helper")

switching_payload.windows = {}
local destroyed_scene = state.normalize(switching_payload, visible_scene.window_visibility)
assert_equal(destroyed_scene.window_visibility["201"], nil,
  "destroyed windows do not leave visibility records behind")

print("window_state_spec: ok")
