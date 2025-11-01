return {
    'nvim-lualine/lualine.nvim',
    cond = function()
        return not vim.g.vscode
    end,
    config = function()
        require('lualine').setup {
            options = {
                icons_enabled = false,
                theme = 'modus-vivendi',--'auto',
                component_separators = { left = '|', right = '|'},
                section_separators = { left = '', right = ''},
            },
            sections = {
                lualine_a = {'mode'},
                lualine_b = {},
                lualine_c = {{'filename', path=3}, 'filesize'},
                lualine_x = {'encoding', 'fileformat'},
                lualine_y = {'progress'},
                lualine_z = {'location'}
            },
        }
    end
}
