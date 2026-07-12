local M = {}

local labels = {
	path = { "absolute path", "absolute paths" },
	dirname = { "containing directory path", "containing directory paths" },
	filename = { "filename", "filenames" },
	name_without_ext = { "filename without extension", "filenames without extensions" },
}

local selected_or_hovered_count = ya.sync(function()
	local count = 0
	for _ in pairs(cx.active.selected) do
		count = count + 1
	end

	if count == 0 and cx.active.current.hovered then
		return 1
	end

	return count
end)

function M:entry(job)
	local kind = job.args[1]
	local label = labels[kind]
	if not label then
		return
	end

	local count = selected_or_hovered_count()
	-- `copy dirname` copies the current directory when it has no hovered item.
	if count == 0 and kind == "dirname" then
		count = 1
	end
	if count == 0 then
		return
	end

	ya.notify {
		title = "Copy",
		content = string.format("Copied %d %s", count, label[count == 1 and 1 or 2]),
		timeout = 3,
	}
end

return M
