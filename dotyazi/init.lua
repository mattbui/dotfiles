Status:children_add(function(self)
	local time = math.floor(self._current.hovered and self._current.hovered.cha.mtime or 0)
	if time == 0 then
		return ""
	end

	local mtime
	if os.date("%Y", time) == os.date("%Y") then
		mtime = os.date("%b %d %H:%M", time)
	else
		mtime = os.date("%b %d  %Y", time)
	end

	return ui.Span(" " .. mtime .. " | "):style(th.status.perm_type)
end, 500, Status.RIGHT)

function Status:name()
	local hovered = self._current.hovered
	if not hovered then
		return ""
	end

	local path = ya.readable_path(tostring(hovered.url))
	return " " .. ui.printable(path)
end

local size = Linemode.size
function Linemode:size()
	return string.format("%7s", size(self))
end

require("git"):setup {
	order = 500,
}

require("outer-border"):setup()
