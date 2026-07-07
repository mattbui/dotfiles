local function pack_names(arg_lead)
  local names = vim
    .iter(vim.pack.get(nil, { info = false }))
    :map(function(plugin)
      return plugin.spec.name
    end)
    :filter(function(name)
      return vim.startswith(name, arg_lead)
    end)
    :totable()

  table.sort(names)
  return names
end

local function parse_names(opts)
  if opts.args == "" then
    return nil
  end

  return vim.split(opts.args, "%s+", { trimempty = true })
end

local function pack_list()
  local plugins = vim.pack.get(nil, { info = false })
  table.sort(plugins, function(a, b)
    return a.spec.name < b.spec.name
  end)

  local lines = {
    "vim.pack plugins",
    "",
  }

  for _, plugin in ipairs(plugins) do
    local status = plugin.active and "active  " or "inactive"
    local rev = plugin.rev and string.sub(plugin.rev, 1, 8) or "--------"
    table.insert(lines, string.format("%s  %s  %s  %s", status, rev, plugin.spec.name, plugin.spec.src))
  end

  vim.cmd("botright 20new")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "vim-pack-list"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modified = false
end

local function pack_update(opts)
  vim.pack.update(parse_names(opts), {
    force = opts.bang,
  })
end

local function pack_inspect(opts)
  vim.pack.update(parse_names(opts), {
    offline = true,
  })
end

local function pack_restore(opts)
  vim.pack.update(parse_names(opts), {
    force = opts.bang,
    offline = true,
    target = "lockfile",
  })
end

local function pack_prune(opts)
  if not opts.bang then
    vim.notify("Use :PackPrune! to delete inactive vim.pack plugins", vim.log.levels.WARN)
    return
  end

  local names = parse_names(opts)
  if not names then
    names = vim
      .iter(vim.pack.get(nil, { info = false }))
      :filter(function(plugin)
        return not plugin.active
      end)
      :map(function(plugin)
        return plugin.spec.name
      end)
      :totable()
  end

  if #names == 0 then
    vim.notify("No inactive vim.pack plugins to prune")
    return
  end

  vim.pack.del(names, { force = false })
end

local function pack_log()
  vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("log") .. "/nvim-pack.log"))
end

vim.api.nvim_create_user_command("PackList", pack_list, {
  desc = "List vim.pack plugins",
})

vim.api.nvim_create_user_command("PackUpdate", pack_update, {
  bang = true,
  nargs = "*",
  complete = pack_names,
  desc = "Update vim.pack plugins; use ! to skip confirmation",
})

vim.api.nvim_create_user_command("PackInspect", pack_inspect, {
  nargs = "*",
  complete = pack_names,
  desc = "Inspect vim.pack plugins without fetching updates",
})

vim.api.nvim_create_user_command("PackRestore", pack_restore, {
  bang = true,
  nargs = "*",
  complete = pack_names,
  desc = "Restore vim.pack plugins from lockfile; use ! to skip confirmation",
})

vim.api.nvim_create_user_command("PackPrune", pack_prune, {
  bang = true,
  nargs = "*",
  complete = pack_names,
  desc = "Delete inactive vim.pack plugins",
})

vim.api.nvim_create_user_command("PackLog", pack_log, {
  desc = "Open vim.pack update log",
})
