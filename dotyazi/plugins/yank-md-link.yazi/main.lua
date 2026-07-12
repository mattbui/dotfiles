local M = {}

local selected_or_hovered = ya.sync(function()
  local entries = {}

  -- Yazi 26.5 exposes selected entries as Url values. Newer releases expose
  -- File values, so accept both shapes to keep the config forward-compatible.
  for _, item in pairs(cx.active.selected) do
    local url = item.url or item
    entries[#entries + 1] = {
      name = tostring(url.name or ""),
      path = tostring(url),
      is_dir = item.cha and item.cha.is_dir or false,
    }
  end

  local item = cx.active.current.hovered
  if #entries == 0 and item then
    local url = item.url
    entries[1] = {
      name = tostring(url.name or ""),
      path = tostring(url),
      is_dir = item.cha.is_dir,
    }
  end

  return entries
end)

function M:entry()
  local entries = selected_or_hovered()
  if #entries == 0 then
    return
  end

  local links = {}
  for _, entry in ipairs(entries) do
    local label = entry.name ~= "" and entry.name or entry.path
    label = label:gsub("]", "\\]")

    local target = entry.path
    if entry.is_dir and target:sub(-1) ~= "/" then
      target = target .. "/"
    end

    links[#links + 1] = string.format("[%s](%s)", label, target)
  end

  ya.clipboard(table.concat(links, "\n"))
  ya.notify {
    title = "Yank link",
    content = string.format("Copied %d markdown link%s", #links, #links == 1 and "" or "s"),
    timeout = 3,
  }
end

return M
