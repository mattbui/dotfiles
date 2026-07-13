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

local function picker_keys(modes)
  local function action(name)
    return { name, mode = modes }
  end

  return {
    ["<Tab>"] = action("list_down"),
    ["<S-Tab>"] = action("list_up"),
    ["<S-Down>"] = action("select_and_next"),
    ["<S-Up>"] = action("select_and_prev"),
    ["<S-CR>"] = action("qflist"),
    ["<PageDown>"] = action("preview_scroll_down"),
    ["<PageUp>"] = action("preview_scroll_up"),
    ["<M-Down>"] = action("list_scroll_down"),
    ["<M-Up>"] = action("list_scroll_up"),
    ["<C-Up>"] = action("history_back"),
    ["<C-Down>"] = action("history_forward"),
    ["<Esc>"] = action("cancel"),
    ["<C-q>"] = action("cancel"),
    ["<C-h>"] = action("navigate_left"),
    ["<C-j>"] = action("navigate_down"),
    ["<C-k>"] = action("navigate_up"),
    ["<C-l>"] = action("navigate_right"),
    ["<C-u>"] = false,
    ["<C-d>"] = false,
  }
end

snacks.setup({
  picker = {
    enabled = true,
    ui_select = false,
    layout = {
      preset = "default",
      cycle = false,
    },
    layouts = {
      default = {
        layout = {
          height = 0.6,
          backdrop = false,
        },
      },
    },
    actions = {
      git_branch_from_selection = git_branch_from_selection,
      navigate_left = tmux_navigate("Left"),
      navigate_down = tmux_navigate("Down"),
      navigate_up = tmux_navigate("Up"),
      navigate_right = tmux_navigate("Right"),
    },
    sources = {
      git_branches = {
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

vim.keymap.set("n", "<Leader>fd", pick_files_and_directories, {
  silent = true,
  desc = "Find files and directories",
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
