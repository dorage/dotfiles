package = "nvim"
version = "dev-1"
source = {
   url = "git+https://github.com/dorage/nvim-dev-env.git"
}
description = {
   summary = "### package manager",
   detailed = "### package manager",
   homepage = "https://github.com/dorage/nvim-dev-env",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      ["dorage._legacy"] = "lua/dorage/_legacy.lua",
      ["dorage.configs.init"] = "lua/dorage/configs/init.lua",
      ["dorage.configs.shortcuts"] = "lua/dorage/configs/shortcuts.lua",
      ["dorage.lazy"] = "lua/dorage/lazy.lua",
      ["dorage.plugins.discord"] = "lua/dorage/plugins/discord.lua",
      ["dorage.plugins.editor.codespace"] = "lua/dorage/plugins/editor/codespace.lua",
      ["dorage.plugins.editor.editing"] = "lua/dorage/plugins/editor/editing.lua",
      ["dorage.plugins.editor.formatting"] = "lua/dorage/plugins/editor/formatting.lua",
      ["dorage.plugins.editor.markdown"] = "lua/dorage/plugins/editor/markdown.lua",
      ["dorage.plugins.editor.telescope"] = "lua/dorage/plugins/editor/telescope.lua",
      ["dorage.plugins.editor.treesitter"] = "lua/dorage/plugins/editor/treesitter.lua",
      ["dorage.plugins.editor.ui"] = "lua/dorage/plugins/editor/ui.lua",
      ["dorage.plugins.init"] = "lua/dorage/plugins/init.lua",
      ["dorage.plugins.lsp.completion"] = "lua/dorage/plugins/lsp/completion.lua",
      ["dorage.plugins.lsp.config"] = "lua/dorage/plugins/lsp/config.lua",
      ["dorage.plugins.lsp.init"] = "lua/dorage/plugins/lsp/init.lua",
      ["dorage.plugins.snippets.ftypes.all"] = "lua/dorage/plugins/snippets/ftypes/all.lua",
      ["dorage.plugins.snippets.ftypes.markdown"] = "lua/dorage/plugins/snippets/ftypes/markdown.lua",
      ["dorage.plugins.snippets.ftypes.tsserver"] = "lua/dorage/plugins/snippets/ftypes/tsserver.lua",
      ["dorage.plugins.snippets.init"] = "lua/dorage/plugins/snippets/init.lua",
      ["dorage.plugins.themes.dashboard"] = "lua/dorage/plugins/themes/dashboard.lua",
      ["dorage.plugins.themes.init"] = "lua/dorage/plugins/themes/init.lua",
      ["dorage.plugins.themes.moonfly"] = "lua/dorage/plugins/themes/moonfly.lua"
   }
}
