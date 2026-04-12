return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg         = "#07150e",
        dark_bg    = "#05100b",
        darker_bg  = "#040b07",
        lighter_bg = "#202c26",

        fg         = "#c3d2c9",
        dark_fg    = "#929e97",
        light_fg   = "#ccd9d1",
        bright_fg  = "#d2ddd7",
        muted      = "#676e6a",

        red        = "#518f6c",
        yellow     = "#468f67",
        orange     = "#6ba082",
        green      = "#398d60",
        cyan       = "#5fab85",
        blue       = "#37946a",
        purple     = "#5b9c7b",
        brown      = "#40604e",

        bright_red    = "#6fb788",
        bright_yellow = "#63b781",
        bright_green  = "#55b579",
        bright_cyan   = "#4cc58e",
        bright_blue   = "#00ad72",
        bright_purple = "#49b684",

        accent               = "#37946a",
        cursor               = "#c3d2c9",
        foreground           = "#c3d2c9",
        background           = "#07150e",
        selection             = "#202c26",
        selection_foreground = "#c3d2c9",
        selection_background = "#202c26",
      },
    },
    -- set up hot reload
    config = function(_, opts)
      require("aether").setup(opts)
      vim.cmd.colorscheme("aether")
      require("aether.hotreload").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
