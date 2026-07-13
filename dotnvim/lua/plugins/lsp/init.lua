local commands = require("plugins.lsp.commands")
local diagnostics = require("plugins.lsp.diagnostics")
local symbols = require("plugins.lsp.symbols")

vim.diagnostic.config({
  virtual_text = commands.virtual_text_enabled and commands.virtual_text or false,
  signs = diagnostics.signs,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Pyrefly supplements Pyright with fast completions and inlay hints while
-- Pyright is still better at inferencing correct types, signature helps
vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
  settings = {
    python = {
      analysis = {
        autoImportCompletions = false,
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
        useLibraryCodeForTypes = false,
      },
    },
  },
  on_attach = function(client)
    client.server_capabilities.inlayHintProvider = nil
  end,
})

-- Keep Pyrefly completion and inlay hints; Pyright handles the rest.
vim.lsp.config("pyrefly", {
  cmd = { "pyrefly", "lsp" },
  filetypes = { "python" },
  root_markers = {
    "pyrefly.toml",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
  init_options = {
    pyrefly = {
      disableTypeErrors = true,
      analysis = {
        autoImportCompletions = false,
        inlayHints = {
          callArgumentNames = "off",
          functionReturnTypes = true,
          pytestParameters = false,
          variableTypes = true,
        },
      },
      disabledLanguageServices = {
        completion = false,
        inlayHint = false,
        callHierarchy = true,
        codeAction = true,
        codeLens = true,
        definition = true,
        declaration = true,
        documentHighlight = true,
        documentSymbol = true,
        hover = true,
        implementation = true,
        rename = true,
        references = true,
        semanticTokens = true,
        signatureHelp = true,
        typeDefinition = true,
        workspaceSymbol = true,
      },
    },
  },
  on_attach = function(client)
    local capabilities = client.server_capabilities
    capabilities.hoverProvider = false
    capabilities.documentSymbolProvider = false
    capabilities.workspaceSymbolProvider = false
    capabilities.codeActionProvider = false
    capabilities.definitionProvider = false
    capabilities.declarationProvider = false
    capabilities.typeDefinitionProvider = false
    capabilities.referencesProvider = false
    capabilities.documentHighlightProvider = false
    capabilities.renameProvider = false
    capabilities.codeLensProvider = nil
    capabilities.semanticTokensProvider = nil
    capabilities.signatureHelpProvider = nil
    capabilities.implementationProvider = false
    capabilities.callHierarchyProvider = false
  end,
})

vim.lsp.config("ts_ls", {
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.config("lua_ls", {
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

vim.lsp.enable({ "pyright", "pyrefly", "ts_ls", "lua_ls" })

symbols.setup()
require("plugins.lsp.mappings")
