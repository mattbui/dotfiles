local M = {}

local api = vim.api

local function link(group, target)
  api.nvim_set_hl(0, group, { link = target })
end

function M.apply()
  local colors_name = vim.g.colors_name
  if colors_name then
    local module_name = "custom-colors." .. colors_name
    local module_path = "lua/" .. module_name:gsub("%.", "/") .. ".lua"
    if #api.nvim_get_runtime_file(module_path, false) > 0 then
      require(module_name).setup()
    end
  end

  link("BlinkCmpMenuBorder", "FloatBorder")
  link("BlinkCmpDocBorder", "FloatBorder")
  link("BlinkCmpSignatureHelpBorder", "FloatBorder")
  link("SnacksPickerInputBorder", "FloatBorder")
  link("Floaterm", "NormalFloat")
  link("YaziFloat", "NormalFloat")

  require("custom-colors.barbar").setup()
end

function M.setup()
  api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
    group = api.nvim_create_augroup("config.colorscheme", { clear = true }),
    callback = M.apply,
  })

  M.apply()
end

return M
