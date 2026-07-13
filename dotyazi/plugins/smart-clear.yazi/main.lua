--- @sync entry

local M = {}

local aliases = {
	highlight = "find",
	highlights = "find",
	selection = "select",
	yank = "unyank",
	cut = "unyank",
}

local function action_set(args)
	if #args == 0 then
		return nil
	end

	local actions = {}
	for _, action in ipairs(args) do
		if action == "all" then
			return nil
		end
		actions[aliases[action] or action] = true
	end
	return actions
end

local function enabled(actions, action)
	return actions == nil or actions[action]
end

local function next_action(actions)
	if enabled(actions, "find") and cx.active.finder then
		return "find"
	end

	if enabled(actions, "visual") and tostring(cx.active.mode) ~= "normal" then
		return "visual"
	end

	if enabled(actions, "filter") and cx.active.current.files.filter then
		return "filter"
	end

	if enabled(actions, "select") and #cx.active.selected > 0 then
		return "select"
	end

	if enabled(actions, "unyank") and #cx.yanked > 0 then
		return "unyank"
	end

	if enabled(actions, "search") and cx.active.current.cwd.is_search then
		return "search"
	end

	if enabled(actions, "close") then
		return "close"
	end
end

function M:entry(job)
	local action = next_action(action_set(job.args))
	if not action then
		return
	end

	if action == "unyank" or action == "close" then
		ya.emit(action, {})
	else
		ya.emit("escape", { [action] = true })
	end
end

return M
