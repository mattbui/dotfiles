local state = {}

local function canonical_space_number(label)
  if type(label) ~= "string" then
    return nil
  end

  local number = label:match("^space%-([1-9][0-9]*)$")
  return number and tonumber(number) or nil
end

local function number(value)
  return tonumber(value) or 0
end

local function bool(value)
  return value == true or value == "true"
end

function state.window_is_eligible(window)
  return type(window) == "table"
    and number(window.id) > 0
    and number(window.space) > 0
    and type(window.app) == "string"
    and window.app ~= ""
    and window.role == "AXWindow"
    and window.subrole == "AXStandardWindow"
    and not bool(window["is-hidden"])
    and not bool(window["is-minimized"])
    and not bool(window["is-sticky"])
end

local function frame_key(window)
  local frame = window.frame or {}
  return table.concat({
    number(frame.x),
    number(frame.y),
    number(frame.w),
    number(frame.h),
  }, ":")
end

local function group_windows(windows)
  local tiled_groups = {}
  local tiled_by_frame = {}
  local floating = {}

  for _, window in ipairs(windows) do
    if bool(window["is-floating"]) then
      table.insert(floating, window)
    else
      local key = frame_key(window)
      local group = tiled_by_frame[key]
      if not group then
        local frame = window.frame or {}
        group = {
          key = key,
          x = number(frame.x),
          y = number(frame.y),
          windows = {},
        }
        tiled_by_frame[key] = group
        table.insert(tiled_groups, group)
      end
      table.insert(group.windows, window)
    end
  end

  table.sort(tiled_groups, function(left, right)
    if left.x ~= right.x then
      return left.x < right.x
    end
    if left.y ~= right.y then
      return left.y < right.y
    end
    return left.key < right.key
  end)

  for _, group in ipairs(tiled_groups) do
    table.sort(group.windows, function(left, right)
      local left_stack = number(left["stack-index"])
      local right_stack = number(right["stack-index"])
      if left_stack ~= right_stack then
        return left_stack < right_stack
      end
      return number(left.id) < number(right.id)
    end)
  end

  table.sort(floating, function(left, right)
    return number(left.id) < number(right.id)
  end)
  if #floating > 0 then
    table.insert(tiled_groups, {
      key = "floating",
      x = math.huge,
      y = math.huge,
      windows = floating,
    })
  end

  return tiled_groups
end

local function space_drawing_key(space)
  local parts = { tostring(space.id), tostring(space.number) }
  for _, group in ipairs(space.groups) do
    table.insert(parts, "|")
    for _, window in ipairs(group.windows) do
      table.insert(parts, table.concat({
        tostring(window.id),
        window.app,
        bool(window["is-floating"]) and "f" or "t",
      }, ":"))
    end
  end
  return table.concat(parts, ",")
end

function state.normalize(payload, previous_visibility)
  payload = type(payload) == "table" and payload or {}
  previous_visibility = type(previous_visibility) == "table" and previous_visibility or {}

  local scene = {
    spaces = {},
    spaces_by_index = {},
    windows_by_id = {},
    focused_space_id = nil,
    focused_window_id = nil,
    window_visibility = {},
    key = "",
  }

  for _, raw_space in ipairs(payload.spaces or {}) do
    local label_number = canonical_space_number(raw_space.label)
    local id = number(raw_space.id)
    local index = number(raw_space.index)
    if label_number and id > 0 and index > 0 then
      local space = {
        id = id,
        index = index,
        number = label_number,
        is_visible = bool(raw_space["is-visible"]),
        windows = {},
        groups = {},
      }
      table.insert(scene.spaces, space)
      scene.spaces_by_index[index] = space
      if bool(raw_space["has-focus"]) then
        scene.focused_space_id = id
      end
    end
  end

  table.sort(scene.spaces, function(left, right)
    return left.number < right.number
  end)

  for _, window in ipairs(payload.windows or {}) do
    local id = number(window.id)
    if id > 0 then
      local id_key = tostring(id)
      local space = scene.spaces_by_index[number(window.space)]
      local base_eligible = state.window_is_eligible(window)
      local last_visible = previous_visibility[id_key]
      if space and space.is_visible and base_eligible then
        last_visible = bool(window["is-visible"])
      elseif last_visible == nil then
        last_visible = true
      end
      scene.window_visibility[id_key] = last_visible

      local eligible = base_eligible and space ~= nil and last_visible
      scene.windows_by_id[id_key] = {
        eligible = eligible,
        raw = window,
      }
      if eligible and bool(window["has-focus"]) then
        scene.focused_window_id = id_key
      end
      if eligible and space then
        table.insert(space.windows, window)
      end
    end
  end

  local keys = {}
  for _, space in ipairs(scene.spaces) do
    space.groups = group_windows(space.windows)
    space.key = space_drawing_key(space)
    table.insert(keys, space.key)
  end
  scene.key = table.concat(keys, "||")

  return scene
end

return state
