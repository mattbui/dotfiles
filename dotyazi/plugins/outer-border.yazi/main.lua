--- @since 26.5.6

local M = {}

function M:setup(opts)
	opts = opts or {}

	local border_type = opts.type or ui.Border.PLAIN
	local title = opts.title or "Yazi"
	local old_build = Root.build

	local function title_widget(area)
		if title == "" or area.w <= 2 or area.h == 0 then
			return nil
		end

		local max = area.w - 2
		local prefix = " " .. title .. ": "
		local suffix = " "
		local path_max = math.max(0, max - ui.Line(prefix .. suffix):width())
		local cwd = ya.readable_path(tostring(cx.active.current.cwd))
		local text

		if path_max > 0 then
			text = prefix .. ui.truncate(cwd, { max = path_max, rtl = true }) .. suffix
		else
			text = ui.truncate(prefix, { max = max })
		end

		return ui.Line(text):area(ui.Rect {
			x = area.x + 1,
			y = area.y,
			w = math.min(ui.Line(text):width(), max),
			h = 1,
		}):style(th.mgr.border_style)
	end

	Root.layout = function(self)
		local inner = self._area:pad(ui.Pad(1, 1, 1, 1))
		self._chunks = ui.Layout()
			:direction(ui.Layout.VERTICAL)
			:constraints({
				ui.Constraint.Length(0),
				ui.Constraint.Length(Tabs.height()),
				ui.Constraint.Fill(1),
				ui.Constraint.Length(1),
			})
			:split(inner)
	end

	Root.build = function(self, ...)
		old_build(self, ...)

		local style = th.mgr.border_style
		local frame = {
			ui.Border(ui.Edge.ALL):area(self._area):type(border_type):style(style),
		}

		self._frame = frame
	end

	Root.redraw = function(self)
		local elements = {}
		local children = self._children or {}

		if children[1] then
			elements = ya.list_merge(elements, ui.redraw(children[1]))
		end
		elements = ya.list_merge(elements, self._base or {})
		elements = ya.list_merge(elements, self._frame or {})
		local title_element = title_widget(self._area)
		if title_element then
			elements = ya.list_merge(elements, { title_element })
		end
		for i = 2, #children do
			elements = ya.list_merge(elements, ui.redraw(children[i]))
		end

		return elements
	end
end

return M
