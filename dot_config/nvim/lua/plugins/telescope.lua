return {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = function(_, opts)
        local telescope = require("telescope")
        local telescopeConfig = require("telescope.config")

        -- Clone the default Telescope configuration
        local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

        table.insert(vimgrep_arguments, "--hidden")
        table.insert(vimgrep_arguments, "--glob")
        table.insert(vimgrep_arguments, "!**/.git/*")

        return {
            defaults = {
                -- `hidden = true` is not supported in text grep commands.
                vimgrep_arguments = vimgrep_arguments,
            },
            pickers = {
                find_files = {
                    hidden = true,
                    file_ignore_patterns = { "**/.git/*" },
                },
            },
        }
    end
}
