local M = {}

-- Define file patterns for which the linter should be run
local FILE_PATTERNS = { "*.c", "*.h" }

-- Function to create an autocmd in Neovim
local function create_autocmd(event, callback)
    vim.api.nvim_create_autocmd(event, {
        pattern = FILE_PATTERNS,
        callback = callback
    })
end

-- Function to setup the Norminette linter
M.setup = function(args)
    -- Define default options
    local opts = {}

    -- If args is provided, update the options
    if args then
        if args.active == false then
            return
        end

        opts.error_limit = args.error_limit or 10 -- Default value if not provided
        opts.lint_events = args.lint_events or { "BufEnter", "BufWritePost" }
    else
        -- If args is not provided, use default values
        opts.lint_events = { "BufEnter", "BufWritePost" }
        opts.error_limit = 10
    end

    -- Try to load the 'linter' module
    local success, NorminetteFunctions = pcall(require, "nvim-norminette.linter")
    if not success then
        -- If the module fails to load, print an error message and return
        print("Failed to load 'linter' module: " .. NorminetteFunctions)
        return
    end

    -- Create a user command to enable the Norminette linter
    vim.api.nvim_create_user_command('NorminetteEnable', function()
        NorminetteFunctions.Enable_Norminette(opts.error_limit)
    end , {})

    -- Create a user command to disable the Norminette linter
    vim.api.nvim_create_user_command('NorminetteDisable', function()
        NorminetteFunctions.Disable_Norminette()
    end , {})

    -- Define a function to run the Norminette linter
    local function run_norminette()
        return NorminetteFunctions.Run_Norminette_And_Display_Diagnostics(opts.error_limit)
    end

    -- Create an autocmd for each event in opts.lint_events
    for _, event in pairs(opts.lint_events) do
        create_autocmd({event}, run_norminette)
    end
end

return M