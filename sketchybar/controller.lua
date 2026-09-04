local colors = require("colors")
local icon_map = require("icon_map")
local window_state = require("window_state")

local controller = {}

local QUERY_WINDOWS_STATE = CONFIG_DIR .. "/scripts/query-windows-state.sh"
local QUERY_CURRENT_WINDOW = CONFIG_DIR .. "/scripts/query-current-window.sh"
local INITIAL_SPACE_SLOT_CAPACITY = 16

local listener
local dynamic_item_names = {}
local dynamic_bracket_names = {}
local space_views = {}
local applied_space_ids = {}
local window_items = {}
local window_cache = {}
local window_visibility = {}
local applied_scene_key = nil
local desired_focus_id = nil
local applied_focus_id = nil
local focus_revision = 0
local structure_revision = 0
local layout_pending = false
local labels_pending = false

local function window_id(value)
  local parsed = tonumber(value)
  if parsed and parsed > 0 then
    return tostring(math.floor(parsed))
  end
  return nil
end

local function icon_for_app(app)
  return icon_map[app] or icon_map.Default or ":default:"
end

local function selected_properties(selected)
  return {
    icon = {
      color = selected and colors.selected_icon or colors.text,
    },
    background = {
      drawing = true,
      color = selected and colors.selected_fill or colors.transparent,
      height = 20,
      corner_radius = 10,
      border_width = 0,
    },
    blur_radius = selected and 16 or 0,
  }
end

local function set_focus(next_id)
  next_id = window_id(next_id)
  if desired_focus_id == next_id and applied_focus_id == next_id then
    return
  end

  desired_focus_id = next_id
  if applied_focus_id and window_items[applied_focus_id] then
    window_items[applied_focus_id]:set(selected_properties(false))
  end

  if desired_focus_id and window_items[desired_focus_id] then
    window_items[desired_focus_id]:set(selected_properties(true))
    applied_focus_id = desired_focus_id
  else
    applied_focus_id = nil
  end
end

local function remove_dynamic_items()
  for _, name in ipairs(dynamic_bracket_names) do
    sbar.remove(name)
  end
  for _, name in ipairs(dynamic_item_names) do
    sbar.remove(name)
  end

  dynamic_item_names = {}
  dynamic_bracket_names = {}
  space_views = {}
  applied_space_ids = {}
  window_items = {}
  applied_focus_id = nil
end

local function add_item(name, properties)
  local item = sbar.add("item", name, properties)
  table.insert(dynamic_item_names, name)
  return item
end

local function text_properties(text, options)
  options = options or {}
  return {
    position = "center",
    drawing = true,
    width = 16,
    padding_left = options.padding_left or 0,
    padding_right = options.padding_right or 0,
    icon = {
      drawing = true,
      string = text,
      color = colors.text,
      font = {
        family = ".AppleSystemUIFont",
        style = "Bold",
        size = 10.0,
      },
      padding_left = options.icon_padding_left or 0,
      padding_right = options.icon_padding_right or 0,
      y_offset = 0,
    },
    label = { drawing = false },
    background = {
      drawing = false,
      color = colors.transparent,
    },
    blur_radius = 0,
  }
end

local function number_properties(number, populated)
  return text_properties(tostring(number), {
    padding_left = 2,
    padding_right = populated and 0 or 2,
    icon_padding_left = 3,
    icon_padding_right = 3,
  })
end

local function spacer_properties(width, drawing)
  return {
    position = "center",
    drawing = drawing,
    width = width,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false },
    blur_radius = 0,
  }
end

local function hidden_slot_properties()
  return {
    position = "center",
    drawing = false,
    width = 16,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { drawing = false },
    background = {
      drawing = false,
      color = colors.transparent,
    },
    blur_radius = 0,
  }
end

local function window_properties(window, selected, is_last)
  return {
    position = "center",
    drawing = true,
    width = 36,
    padding_left = 0,
    padding_right = is_last and 2 or 0,
    icon = {
      drawing = true,
      string = icon_for_app(window.app),
      color = selected and colors.selected_icon or colors.text,
      align = "center",
      font = {
        family = "sketchybar-app-font",
        style = "Regular",
        size = 16.0,
      },
      padding_left = 0,
      padding_right = 0,
      y_offset = 0,
    },
    label = { drawing = false },
    background = {
      drawing = true,
      color = selected and colors.selected_fill or colors.transparent,
      height = 20,
      corner_radius = 10,
      border_width = 0,
    },
    blur_radius = selected and 16 or 0,
  }
end

local function content_cells(space)
  local cells = {}
  for group_index, group in ipairs(space.groups) do
    if group_index > 1 then
      table.insert(cells, { kind = "separator" })
    end
    for _, window in ipairs(group.windows) do
      table.insert(cells, { kind = "window", window = window })
    end
  end
  return cells
end

local function cell_key(cell, is_last)
  if not cell then
    return "hidden"
  end
  if cell.kind == "separator" then
    return "separator"
  end
  return table.concat({
    "window",
    tostring(cell.window.id),
    cell.window.app,
    is_last and "last" or "middle",
  }, ":")
end

local function properties_for_cell(cell, is_last)
  if not cell then
    return hidden_slot_properties()
  end
  if cell.kind == "separator" then
    return text_properties("·", { icon_padding_right = 3 })
  end
  local id = window_id(cell.window.id)
  return window_properties(cell.window, id == desired_focus_id, is_last)
end

local function create_space_view(space, is_last)
  local prefix = "space." .. tostring(space.id)
  local cells = content_cells(space)
  local populated = #cells > 0
  local capacity = math.max(INITIAL_SPACE_SLOT_CAPACITY, #cells)
  local members = {}
  local view = {
    id = space.id,
    capacity = capacity,
    slots = {},
    number_key = tostring(space.number) .. ":" .. tostring(populated),
    number_gap_drawing = populated,
    gap_drawing = not is_last,
  }

  view.number = add_item(prefix .. ".number", number_properties(space.number, populated))
  table.insert(members, view.number.name)
  view.number_gap = add_item(
    prefix .. ".number-gap",
    spacer_properties(4, populated)
  )
  table.insert(members, view.number_gap.name)

  for index = 1, capacity do
    local cell = cells[index]
    local is_last_cell = index == #cells
    local slot = add_item(
      prefix .. ".content." .. tostring(index),
      properties_for_cell(cell, is_last_cell)
    )
    view.slots[index] = {
      item = slot,
      key = cell_key(cell, is_last_cell),
    }
    table.insert(members, slot.name)
    if cell and cell.kind == "window" then
      local id = window_id(cell.window.id)
      window_items[id] = slot
      if id == desired_focus_id then
        applied_focus_id = id
      end
    end
  end

  view.bracket_name = prefix .. ".pill"
  sbar.add("bracket", view.bracket_name, members, {
    background = {
      drawing = true,
      color = colors.space_fill,
      border_color = colors.space_border,
      border_width = 1,
      height = 24,
      corner_radius = 12,
    },
    blur_radius = 20,
  })
  table.insert(dynamic_bracket_names, view.bracket_name)

  view.gap = add_item(prefix .. ".space-gap", spacer_properties(12, not is_last))
  space_views[tostring(space.id)] = view
end

local function can_update_scene_in_place(scene)
  if #scene.spaces ~= #applied_space_ids then
    return false
  end
  for index, space in ipairs(scene.spaces) do
    local view = space_views[tostring(space.id)]
    if applied_space_ids[index] ~= space.id or not view then
      return false
    end
    if #content_cells(space) > view.capacity then
      return false
    end
  end
  return true
end

local function update_space_view(view, space, is_last)
  local cells = content_cells(space)
  local populated = #cells > 0
  local next_number_key = tostring(space.number) .. ":" .. tostring(populated)
  if view.number_key ~= next_number_key then
    view.number:set(number_properties(space.number, populated))
    view.number_key = next_number_key
  end
  if view.number_gap_drawing ~= populated then
    view.number_gap:set(spacer_properties(4, populated))
    view.number_gap_drawing = populated
  end
  local gap_drawing = not is_last
  if view.gap_drawing ~= gap_drawing then
    view.gap:set(spacer_properties(12, gap_drawing))
    view.gap_drawing = gap_drawing
  end

  for index, slot in ipairs(view.slots) do
    local cell = cells[index]
    local is_last_cell = index == #cells
    local next_key = cell_key(cell, is_last_cell)
    if slot.key ~= next_key then
      slot.item:set(properties_for_cell(cell, is_last_cell))
      slot.key = next_key
    end
    if cell and cell.kind == "window" then
      window_items[window_id(cell.window.id)] = slot.item
    end
  end
end

local function rebuild_scene(scene)
  remove_dynamic_items()
  for index, space in ipairs(scene.spaces) do
    applied_space_ids[index] = space.id
    create_space_view(space, index == #scene.spaces)
  end
end

local function render_scene(scene)
  if scene.key == applied_scene_key then
    return false
  end

  if not can_update_scene_in_place(scene) then
    rebuild_scene(scene)
  else
    window_items = {}
    for index, space in ipairs(scene.spaces) do
      update_space_view(space_views[tostring(space.id)], space, index == #scene.spaces)
    end
    if applied_focus_id and not window_items[applied_focus_id] then
      applied_focus_id = nil
    end
  end

  applied_scene_key = scene.key
  return true
end

local function query_scene(expected_revision, attempt)
  local captured_focus_revision = focus_revision
  sbar.exec(QUERY_WINDOWS_STATE, function(payload, exit_code)
    if expected_revision ~= structure_revision then
      return
    end
    if exit_code ~= 0 then
      if (attempt or 1) < 3 then
        sbar.delay(0.08, function()
          if expected_revision == structure_revision then
            query_scene(expected_revision, (attempt or 1) + 1)
          end
        end)
      end
      return
    end

    local scene = window_state.normalize(payload, window_visibility)
    window_visibility = scene.window_visibility
    window_cache = scene.windows_by_id

    if captured_focus_revision == focus_revision then
      if not desired_focus_id then
        desired_focus_id = scene.focused_window_id
      end
      local focused_record = desired_focus_id and window_cache[desired_focus_id] or nil
      local focused_space_empty = false
      for _, space in ipairs(scene.spaces) do
        if space.id == scene.focused_space_id then
          focused_space_empty = #space.windows == 0
          break
        end
      end

      if desired_focus_id
        and (not focused_record or not focused_record.eligible or focused_space_empty) then
        set_focus(nil)
      end
    end

    render_scene(scene)
    set_focus(desired_focus_id)
  end)
end

local function schedule_query(delay)
  structure_revision = structure_revision + 1
  local expected_revision = structure_revision
  sbar.delay(delay or 0, function()
    if expected_revision ~= structure_revision then
      return
    end
    if layout_pending or labels_pending then
      return
    end
    query_scene(expected_revision, 1)
  end)
end

local function schedule_guarded_fallback(delay)
  local expected_revision = structure_revision
  sbar.delay(delay, function()
    if expected_revision ~= structure_revision then
      return
    end
    layout_pending = false
    labels_pending = false
    schedule_query(0)
  end)
end

local function mark_layout_pending()
  layout_pending = true
  structure_revision = structure_revision + 1
  schedule_guarded_fallback(0.35)
end

local function mark_labels_pending()
  labels_pending = true
  structure_revision = structure_revision + 1
  schedule_guarded_fallback(0.35)
end

local function query_unknown_focus(id, expected_focus_revision)
  sbar.exec(QUERY_CURRENT_WINDOW .. " " .. id, function(window, exit_code)
    if expected_focus_revision ~= focus_revision then
      return
    end
    if exit_code == 0 and window_state.window_is_eligible(window) then
      desired_focus_id = id
      schedule_query(0)
    elseif exit_code == 0 then
      set_focus(nil)
    else
      schedule_query(0.04)
    end
  end)
end

local function handle_window_focus(env)
  local id = window_id(env.WINDOW_ID)
  if not id then
    return
  end

  focus_revision = focus_revision + 1
  if desired_focus_id == id and applied_focus_id == id then
    return
  end

  local cached = window_cache[id]
  if cached and cached.eligible then
    set_focus(id)
    return
  end

  query_unknown_focus(id, focus_revision)
end

local layout_events = {
  space_changed = true,
  display_changed = true,
  window_created = true,
  window_destroyed = true,
  window_minimized = true,
  window_deminimized = true,
  application_hidden = true,
  application_visible = true,
}

local label_events = {
  space_created = true,
  space_destroyed = true,
  display_added = true,
  display_removed = true,
  display_moved = true,
  display_resized = true,
}

local direct_events = {
  window_moved = true,
  window_resized = true,
  application_terminated = true,
  mission_control_exit = true,
}

local function handle_yabai_event(env)
  local event = env.EVENT
  if event == "window_focused" then
    handle_window_focus(env)
  elseif event == "layout_completed" then
    layout_pending = false
    schedule_query(0)
  elseif event == "labels_completed" then
    labels_pending = false
    schedule_query(0)
  elseif layout_events[event] then
    mark_layout_pending()
  elseif label_events[event] then
    mark_labels_pending()
    if event == "display_resized" then
      layout_pending = true
    end
  elseif direct_events[event] then
    if not layout_pending and not labels_pending then
      schedule_query(0.05)
    end
  end
end

function controller.setup()
  -- A hot reload starts a new Lua process, so its in-memory item registry cannot
  -- remove items created by the previous process. Clear only our dynamic items.
  sbar.remove("/space\\..*/")

  sbar.add("event", "yabai_event")
  listener = sbar.add("item", "yabai.event.listener", {
    position = "center",
    drawing = false,
    updates = true,
  })
  listener:subscribe("yabai_event", handle_yabai_event)
  listener:subscribe("system_woke", function()
    layout_pending = false
    labels_pending = false
    schedule_query(0.1)
  end)

  schedule_query(0)
end

return controller
