return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
    cond = function()
        return not vim.g.vscode
    end,
    config = function()
        require("ibl").setup()
    end
}
