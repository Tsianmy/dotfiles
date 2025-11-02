vim.cmd('source ~/.xvimrc')
require("config.lazy")

if not vim.g.vscode then
    vim.o.termguicolors = true
    vim.loop.fs_write(2, "\27Ptmux;\27\27]11;?\7\27\\", -1, nil)
    vim.opt.list = true
    vim.opt.listchars = { tab = "⟼ ", leadmultispace = "·", trail = "·" }
    vim.cmd("highlight Nontext guifg=#bbbdc4")
end

---- neovide ----
if vim.g.neovide then
    if vim.fn.has('windows') then
        vim.o.guifont = 'Ubuntu Mono:h16'
    else
        vim.o.guifont = 'Ubuntu Mono:h18'
    end
    vim.o.linespace = 4
    --vim.o.hidden = false
    --vim.o.confirm = true
    vim.g.neovide_theme = 'light'
    --[[
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0.00
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_scroll_animation_far_lines = 0
    vim.g.neovide_scroll_animation_length = 0.00
    ]]

end

