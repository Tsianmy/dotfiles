return {
    "andre-kotake/nvim-chezmoi",
    opts = function(_, opts)
        local M = require("nvim-chezmoi")
        local setup_plugin = function()
            local chezmoi_edit = require("nvim-chezmoi.chezmoi.commands.edit")
            local chezmoi_apply = require("nvim-chezmoi.chezmoi.commands.apply")
            local chezmoi_exec_tmpl =
                require("nvim-chezmoi.chezmoi.commands.execute_template")

            -- Create autocmds and cmds
            chezmoi_exec_tmpl:init(M.opts.execute_template)
            chezmoi_edit:init(M.opts)
            chezmoi_edit:create_user_commands()
            chezmoi_apply:create_user_commands()

            vim.api.nvim_create_augroup("NvimChezmoi", {})
            vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
                group = "NvimChezmoi",
                pattern = M.opts.source_path .. "/*",
                callback = function(ev)
                    chezmoi_edit:on_edit(ev.buf)
                end,
            })

            require("nvim-chezmoi.core.telescope").init(M.opts.source_path)
        end
        M.setup = function(opts)
            M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

            if M.opts.source_path ~= nil then
                setup_plugin()
            else
                require("nvim-chezmoi.chezmoi.commands.source_path"):async(
                    {},
                    function(result)
                        if not result.success then
                            return
                        end

                        M.opts.source_path = result.data[1]
                        setup_plugin()

                        -- Create buf user commands for already opened source file buffer.
                        local utils = require("nvim-chezmoi.core.utils")
                        for _, buf in ipairs(vim.fn.getbufinfo({ buf = "buflisted" })) do
                            local file_path = vim.fn.bufname(buf.bufnr)
                            -- Only check buffers with a valid file path
                            if
                                file_path ~= "" and utils.is_child_of(M.opts.source_path, file_path)
                            then
                                vim.api.nvim_exec_autocmds({ "BufRead" }, {
                                    group = "NvimChezmoi",
                                    buffer = buf.bufnr,
                                })
                            end
                        end
                  end
                )
            end
        end
        vim.api.nvim_create_autocmd({ "BufRead" }, {
            callback = function(ev)
                require("nvim-chezmoi.chezmoi.commands.source_path"):async(
                    { ev.file },
                    function(result)
                        if result.success then
                            local file = result.data[1]
                            if vim.uv.fs_stat(file) then
                                vim.cmd.edit(file)
                            end
                        end
                    end
                )
            end
        })

    end,
}
