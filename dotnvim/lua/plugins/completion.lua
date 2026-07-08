local cmp = require("blink.cmp")

local function check_back_space()
  local col = vim.fn.col(".") - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
end

cmp.setup({
  keymap = {
    preset = "none",
    ["<Tab>"] = {
      function(blink)
        if not blink.is_visible() and check_back_space() then
          return false
        end
        return blink.insert_next()
      end,
      "fallback",
    },
    ["<S-Tab>"] = { "insert_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
  },
  sources = {
    default = { "lsp", "path", "buffer" },
  },
  fuzzy = {
    implementation = "prefer_rust",
  },
  completion = {
    menu = {
      border = "single",
    },
    list = {
      selection = {
        preselect = false,
      },
    },
    documentation = {
      auto_show = true,
      window = {
        border = "single",
      },
    },
  },
  signature = {
    enabled = true,
    window = {
      border = "single",
    },
  },
  term = {
    enabled = false,
  },
  cmdline = {
    keymap = {
      preset = "none",
      ["<Tab>"] = { "show_and_insert_or_accept_single", "select_next" },
      ["<S-Tab>"] = {
        function(blink)
          return blink.show_and_insert_or_accept_single({ initial_selected_item_idx = -1 })
        end,
        "select_prev",
      },
      ["<Down>"] = {
        function(blink)
          return blink.select_next({ auto_insert = true })
        end,
        "fallback",
      },
      ["<Up>"] = {
        function(blink)
          return blink.select_prev({ auto_insert = true })
        end,
        "fallback",
      },
      ["<CR>"] = { "accept_and_enter", "fallback" },
    },
    completion = {
      menu = { auto_show = true },
      list = {
        selection = {
          preselect = false,
        },
      },
    },
  },
})
