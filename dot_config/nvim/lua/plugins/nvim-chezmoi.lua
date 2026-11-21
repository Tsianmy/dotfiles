return {
    "andre-kotake/nvim-chezmoi",
    dependencies = {
        { "folke/snacks.nvim" },
    },
    -- BufReadPre catches the first file opened on the command line;
    -- VimEnter makes the :Chezmoi* commands available in empty sessions.
    event = { "BufReadPre", "VimEnter" },
    opts = {},
    config = function(_, opts)
        require("nvim-chezmoi").setup(opts)

        local source_path_cmd =
            require("nvim-chezmoi.chezmoi.commands.source_path")
        local managed_cmd = require("nvim-chezmoi.chezmoi.commands.managed")
        local helper = require("nvim-chezmoi.chezmoi.helper")

        local CACHE_VERSION = 1
        local cache_file = vim.fs.joinpath(
            vim.fn.stdpath("cache"),
            "nvim-chezmoi",
            "managed.json"
        )

        ---@type table<string, string>|nil target path -> source state path
        local managed = nil
        local cached_source_path = nil

        local function load_cache()
            local ok, lines = pcall(vim.fn.readfile, cache_file)
            if not ok or #lines == 0 then
                return
            end

            local decoded_ok, data =
                pcall(vim.json.decode, table.concat(lines, "\n"))
            if
                not decoded_ok
                or type(data) ~= "table"
                or data.version ~= CACHE_VERSION
                or type(data.files) ~= "table"
            then
                return
            end

            managed = data.files
            cached_source_path = data.source_path
        end
        load_cache()

        local refreshing = false
        local function refresh_managed()
            if refreshing then
                return
            end
            refreshing = true

            managed_cmd:async({}, function(result)
                refreshing = false
                if not result.success then
                    return
                end

                local map = {}
                for _, file in pairs(result.data) do
                    if file.absolute and file.sourceAbsolute then
                        map[vim.fs.normalize(file.absolute)] = file.sourceAbsolute
                    end
                end

                if not next(map) then
                    return
                end

                managed = map
                cached_source_path = require("nvim-chezmoi").opts.source_path

                pcall(vim.fn.mkdir, vim.fs.dirname(cache_file), "p")
                pcall(vim.fn.writefile, {
                    vim.json.encode({
                        version = CACHE_VERSION,
                        source_path = cached_source_path,
                        files = map,
                    }),
                }, cache_file)
            end)
        end

        local refresh_scheduled = false
        local function schedule_refresh()
            if refresh_scheduled then
                return
            end
            refresh_scheduled = true

            -- Give the initial target -> source lookup a head start.
            vim.defer_fn(function()
                refresh_scheduled = false
                refresh_managed()
            end, 1500)
        end

        if not managed then
            schedule_refresh()
        end

        vim.api.nvim_create_user_command(
            "ChezmoiRefreshManagedCache",
            refresh_managed,
            { desc = "Refresh the nvim-chezmoi managed files cache" }
        )

        local pending = {}
        local group = vim.api.nvim_create_augroup(
            "NvimChezmoiFollowSource",
            { clear = true }
        )

        local function is_under(root, file)
            root = vim.fs.normalize(root):gsub("/+$", "")
            file = vim.fs.normalize(file)

            return file == root or file:sub(1, #root + 1) == root .. "/"
        end

        ---Replace the target buffer with its source state file.
        local function follow(buf, file, source)
            if source == nil or source == "" or source == file then
                return
            end
            source = vim.fs.normalize(source)

            -- The user may have switched buffers while chezmoi was running.
            if
                not vim.api.nvim_buf_is_valid(buf)
                or vim.api.nvim_get_current_buf() ~= buf
                or vim.api.nvim_buf_get_name(buf) ~= file
            then
                return
            end

            if not vim.uv.fs_stat(source) then
                return
            end

            if helper.is_encrypted(source) then
                -- Let the plugin decrypt it into a scratch buffer.
                require("nvim-chezmoi.chezmoi.commands.edit"):exec(file)
            else
                vim.cmd.edit({ args = { vim.fn.fnameescape(source) } })
            end
        end

        vim.api.nvim_create_autocmd("BufReadPost", {
            group = group,
            callback = function(ev)
                local buf = ev.buf
                local file = vim.api.nvim_buf_get_name(buf)

                if
                    file == ""
                    or vim.bo[buf].buftype ~= ""
                    or vim.fn.isdirectory(file) == 1
                then
                    return
                end

                -- Do not redirect buffers that already are source state files.
                local source_root =
                    require("nvim-chezmoi").opts.source_path or cached_source_path
                if source_root and is_under(source_root, file) then
                    return
                end

                local normalized = vim.fs.normalize(file)
                local source = managed and managed[normalized]

                if source and vim.uv.fs_stat(source) then
                    follow(buf, file, source)
                    return
                end

                -- Cache miss or stale entry: ask chezmoi, then refresh the cache.
                if pending[normalized] then
                    return
                end
                pending[normalized] = true

                source_path_cmd:async({ file }, function(result)
                    pending[normalized] = nil
                    if not result.success then
                        return
                    end

                    follow(buf, file, result.data[1])
                    schedule_refresh()
                end)
            end,
        })
    end,
}
