pcall(vim.cmd.packadd, "snacks.nvim")

local ok, snacks = pcall(require, "snacks")
if not ok then
  vim.schedule(function()
    vim.notify("snacks.nvim is not available; run vim.pack update/repair", vim.log.levels.WARN)
  end)
  return
end

local function tmux_navigate(direction)
  return function(picker)
    picker:close()
    vim.schedule(function()
      vim.cmd("TmuxNavigate" .. direction)
    end)
  end
end

local function git_branch_from_selection(picker, item)
  local base = item and (item.branch or item.commit)
  if not base then
    snacks.notify.warn("No branch selected", { title = "Snacks Picker" })
    return
  end

  vim.ui.input({ prompt = "New branch from " .. base .. ": " }, function(name)
    name = vim.trim(name or "")
    if name == "" then
      return
    end

    local cwd = item.cwd or picker:cwd()
    picker:close()
    snacks.picker.util.cmd({ "git", "checkout", "-b", name, base }, function()
      snacks.notify("Created branch `" .. name .. "` from `" .. base .. "`", { title = "Snacks Picker" })
      vim.cmd.checktime()
    end, { cwd = cwd })
  end)
end

local function git_discard(picker)
  local items = picker:selected({ fallback = true })
  if #items == 0 then
    return
  end

  local tracked = {}
  local untracked = {}
  local files = {}
  for _, item in ipairs(items) do
    if not item.status or not item.file then
      snacks.notify.warn("Can't discard this change", { title = "Snacks Picker" })
      return
    end

    files[#files + 1] = snacks.picker.util.path(item)
    local target = item.status == "??" and untracked or tracked
    target[#target + 1] = item.file
  end

  local msg
  if #items == 1 and #untracked == 1 then
    msg = ("Delete untracked `%s`?"):format(files[1])
  elseif #untracked > 0 then
    local noun = #untracked == 1 and "file" or "files"
    msg = ("Discard %d files, delete %d untracked %s?"):format(#items, #untracked, noun)
  else
    msg = #items == 1 and ("Discard `%s`?"):format(files[1]) or ("Discard %d files?"):format(#items)
  end

  snacks.picker.util.confirm(msg, function()
    local commands = {}
    if #tracked > 0 then
      commands[#commands + 1] = vim.list_extend({ "git", "restore", "--" }, tracked)
    end
    if #untracked > 0 then
      commands[#commands + 1] = vim.list_extend({ "git", "clean", "-f", "--" }, untracked)
    end

    local done = 0
    for _, command in ipairs(commands) do
      snacks.picker.util.cmd(command, function()
        done = done + 1
        if done == #commands then
          vim.schedule(function()
            picker:refresh()
            vim.cmd.startinsert()
            vim.cmd.checktime()
          end)
        end
      end, { cwd = items[1].cwd })
    end
  end)
end

local function picker_keys(modes)
  return {
    ["<Tab>"] = { "list_down", mode = modes },
    ["<S-Tab>"] = { "list_up", mode = modes },
    ["<S-Down>"] = { "select_and_next", mode = modes },
    ["<S-Up>"] = { "select_and_prev", mode = modes },
    ["J"] = { "select_and_next", mode = "n" },
    ["K"] = { "select_and_prev", mode = "n" },
    ["<S-CR>"] = { "qflist", mode = modes },
    ["<PageDown>"] = { "preview_scroll_down", mode = modes },
    ["<PageUp>"] = { "preview_scroll_up", mode = modes },
    ["<M-Down>"] = { "list_scroll_down", mode = modes },
    ["<M-Up>"] = { "list_scroll_up", mode = modes },
    ["<C-Up>"] = { "history_back", mode = modes },
    ["<C-Down>"] = { "history_forward", mode = modes },
    ["<Esc>"] = { "cancel", mode = modes },
    ["<C-q>"] = { "cancel", mode = modes },
    ["<C-h>"] = { "navigate_left", mode = modes },
    ["<C-j>"] = { "navigate_down", mode = modes },
    ["<C-k>"] = { "navigate_up", mode = modes },
    ["<C-l>"] = { "navigate_right", mode = modes },
    ["<C-u>"] = false,
    ["<C-d>"] = false,
  }
end

snacks.setup({
  picker = {
    prompt = "🍿 ",
    enabled = true,
    ui_select = false,
    layout = {
      preset = "default",
      cycle = false,
    },
    layouts = {
      default = {
        config = function(layout)
          -- input/list window
          layout.layout[1].title_pos = "left"
          -- preview window
          layout.layout[2].title_pos = "left"
          layout.layout[2].width = 0.55
        end,
        layout = {
          width = 0.8,
          height = 0.6,
          backdrop = false,
        },
      },
    },
    actions = {
      git_branch_from_selection = git_branch_from_selection,
      git_discard = git_discard,
      navigate_left = tmux_navigate("Left"),
      navigate_down = tmux_navigate("Down"),
      navigate_up = tmux_navigate("Up"),
      navigate_right = tmux_navigate("Right"),
    },
    sources = {
      git_status = {
        title = "Git Status · ^s stage/unstage · ^x discard",
        win = {
          input = {
            keys = {
              ["<C-s>"] = { "git_stage", mode = { "n", "i" }, desc = "Stage/unstage" },
              ["<C-x>"] = { "git_discard", mode = { "n", "i" }, nowait = true, desc = "Discard changes" },
            },
          },
          list = {
            keys = {
              ["<C-s>"] = { "git_stage", mode = "n", desc = "Stage/unstage" },
              ["<C-x>"] = { "git_discard", mode = "n", nowait = true, desc = "Discard changes" },
            },
          },
        },
      },
      git_branches = {
        title = "Git Branches · ^a new@HEAD · ^b new@selected · ^x delete",
        win = {
          input = {
            keys = {
              ["<C-a>"] = { "git_branch_add", mode = { "n", "i" }, desc = "New branch from HEAD" },
              ["<C-b>"] = { "git_branch_from_selection", mode = { "n", "i" }, desc = "New branch from selected" },
              ["<C-x>"] = { "git_branch_del", mode = { "n", "i" }, desc = "Delete branch" },
            },
          },
          list = {
            keys = {
              ["<C-a>"] = { "git_branch_add", mode = "n", desc = "New branch from HEAD" },
              ["<C-b>"] = { "git_branch_from_selection", mode = "n", desc = "New branch from selected" },
              ["<C-x>"] = { "git_branch_del", mode = "n", desc = "Delete branch" },
            },
          },
        },
      },
    },
    win = {
      input = {
        keys = picker_keys({ "n", "i" }),
      },
      list = {
        keys = picker_keys("n"),
      },
      preview = {
        keys = {
          ["<PageDown>"] = "preview_scroll_down",
          ["<PageUp>"] = "preview_scroll_up",
          ["<Esc>"] = "cancel",
          ["<C-q>"] = "cancel",
          ["<C-h>"] = "navigate_left",
          ["<C-j>"] = "navigate_down",
          ["<C-k>"] = "navigate_up",
          ["<C-l>"] = "navigate_right",
        },
      },
    },
  },
})

local function pick_files_and_directories(opts)
  opts = opts or {}

  snacks.picker.pick({
    title = "Files and directories",
    cwd = opts.cwd,
    format = "file",
    preview = "file",
    finder = function(finder_opts, ctx)
      local cwd = vim.fs.normalize(finder_opts.cwd or ctx:cwd() or vim.uv.cwd() or ".")
      return require("snacks.picker.source.proc").proc(ctx:opts({
        cmd = "fd",
        args = { "--hidden", "--type", "f", "--type", "d", "--color", "never" },
        cwd = cwd,
        transform = function(item)
          if item.text == "" then
            return false
          end

          local is_dir = item.text:sub(-1) == "/"
          local path = item.text:gsub("/$", "")

          item.text = path
          item.file = path
          item.cwd = cwd
          item.dir = is_dir
        end,
      }), ctx)
    end,
    -- Open the current directory in Yazi; otherwise jump to selected files only.
    confirm = function(picker, item)
      if not item then
        return
      end

      if item.dir then
        local path = snacks.picker.util.path(item)
        picker:close()
        vim.schedule(function()
          require("yazi").yazi(nil, path)
        end)
        return
      end

      picker.list:set_selected(vim.tbl_filter(function(selected)
        return not selected.dir
      end, picker.list.selected))
      picker:action("jump")
    end,
  })
end

local function pick_config_files()
  local home = vim.fs.normalize(assert(vim.uv.os_homedir(), "Could not resolve home directory"))
  local config_home = vim.fs.normalize(vim.env.XDG_CONFIG_HOME or (home .. "/.config"))

  snacks.picker.pick({
    title = "Config files",
    cwd = "/",
    format = "file",
    preview = "file",
    finder = function(_, ctx)
      local proc = require("snacks.picker.source.proc")
      local seen = {}

      local function source(args)
        return proc.proc(ctx:opts({
          cmd = "fd",
          args = args,
          cwd = home,
          transform = function(item)
            if item.text == "" then
              return false
            end

            local path = vim.fs.normalize(item.text)
            if seen[path] then
              return false
            end
            seen[path] = true

            if vim.startswith(path, home .. "/") then
              local relative = path:sub(#home + 2)
              item.text = relative
              item.file = relative
              item.cwd = home
            else
              item.text = path
              item.file = path
              item.cwd = nil
            end
          end,
        }), ctx)
      end

      local config_files = source({
        "--hidden",
        "--no-require-git",
        "--follow",
        "--type",
        "f",
        "--color",
        "never",
        "--exclude",
        ".git",
        "--exclude",
        "*backup*",
        ".",
        config_home,
      })

      local named_args = {
        "--hidden",
        "--no-require-git",
        "--follow",
        "--type",
        "f",
        "--max-depth",
        "4",
        "--color",
        "never",
        "--exclude",
        ".git",
        "--exclude",
        ".cache",
        "--exclude",
        ".Trash",
        "--exclude",
        "Library",
        "--exclude",
        "node_modules",
        "--exclude",
        "*backup*",
      }

      -- Exclude config dir if it's within home
      if vim.startswith(config_home, home .. "/") then
        vim.list_extend(named_args, { "--exclude", config_home:sub(#home + 2) })
      end

      vim.list_extend(named_args, {
        "^(?:config(?:\\.(?:ya?ml|toml|json))?|.*rc)$",
        home,
      })

      local named_configs = source(named_args)

      return function(cb)
        named_configs(cb)
        config_files(cb)
      end
    end,
  })
end

vim.keymap.set("n", "<Leader>fd", pick_files_and_directories, {
  silent = true,
  desc = "Find files and directories",
})

vim.keymap.set("n", "<Leader>fc", pick_config_files, {
  silent = true,
  desc = "Find config files",
})

vim.keymap.set("n", "<Leader>ld", function()
  snacks.picker.diagnostics_buffer()
end, { silent = true, desc = "Document diagnostics" })

vim.keymap.set("n", "<Leader>lD", function()
  snacks.picker.diagnostics()
end, { silent = true, desc = "All diagnostics" })

vim.keymap.set("n", "<Leader>ls", function()
  snacks.picker.lsp_symbols()
end, { silent = true, desc = "Document symbols" })

vim.keymap.set("n", "<Leader>lS", function()
  snacks.picker.lsp_workspace_symbols()
end, { silent = true, desc = "Workspace symbols" })

vim.keymap.set("n", "<Leader>gb", function()
  snacks.picker.git_branches()
end, { silent = true, desc = "Branch" })

vim.keymap.set("n", "<Leader>gf", function()
  snacks.picker.git_status()
end, { silent = true, desc = "Dirty files" })
