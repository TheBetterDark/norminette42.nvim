local M = {}

-- Flag to indicate whether the Norminette plugin is enabled
local is_enabled = true

-- Constants for the start and end positions of the error code, line, column, and message in the Norminette output
local ERROR_CODE_START = 8
local ERROR_CODE_END = 28
local ERROR_LINE_START = 35
local ERROR_LINE_END = 38
local ERROR_COLUMN_START = 45
local ERROR_COLUMN_END = 48
local ERROR_MESSAGE_START = 52

-- Function to check if a string is empty or nil
function M.Is_Empty(str)
    return str == nil or str == ""
end

-- Function to trim leading and trailing whitespace from a string
function M.Trim_String(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

-- Function to get the error message if the error index is less than the maximum number of errors to show
function M.Get_Errors(index, error_limit, error_msg)
    if error_limit == nil or index < (error_limit + 2) then
        return error_msg
    else
        return nil
    end
end

-- Function to parse the Norminette output and create a diagnostic table
function M.Parse_Error(error_list, buffer_handle, error_limit)
    local diagnostic_table = {}

    for index, value in ipairs(error_list) do
        if index ~= 1 then
            local error_code = M.Trim_String((string.sub(value, ERROR_CODE_START, ERROR_CODE_END))) or "Error getting error-code"
            local error_line = tonumber(string.sub(value, ERROR_LINE_START, ERROR_LINE_END), 10) or 1
            local error_column  = tonumber(string.sub(value, ERROR_COLUMN_START, ERROR_COLUMN_END), 10) or 1
            local error_msg = M.Trim_String((string.sub(value, ERROR_MESSAGE_START))) or "Error getting error-message"

            table.insert(diagnostic_table, {
                bufnr = buffer_handle,
                message = M.Get_Errors(index, error_limit, error_msg),
                lnum = error_line - 1,
                end_lnum = error_line - 1,
                col = error_column - 1,
                end_col = error_column,
                severity = vim.diagnostic.severity.ERROR,
                source = "norminette",
                code = error_code,
                user_data = {}
            })
        end
    end
    return diagnostic_table
end

-- Function to enable the Norminette plugin
function M.Enable_Norminette(error_limit)
    is_enabled = true
    M.Norminette(error_limit)
end

-- Function to disable the Norminette plugin
function M.Disable_Norminette()
    is_enabled = false
    vim.diagnostic.reset()
end

-- Function to run the Norminette M and display the results
function M.Run_Norminette_And_Display_Diagnostics(error_limit)
    if not is_enabled then
        return  
    end

    local buffer_handle = vim.api.nvim_get_current_buf()
    local current_buffer_name = vim.api.nvim_buf_get_name(buffer_handle)
    local name_space_id = vim.api.nvim_create_namespace("nvim-normintte")
    local return_table = {}
    local file_handle = assert(io.popen("norminette " .. current_buffer_name, "r"))
    
    local index = 1
    repeat
        local line = file_handle:read("*l")
        return_table[index] = line
        index = index + 1
    until (M.Is_Empty(line))
    file_handle:close()

    local diagnostics = M.Parse_Error(return_table, buffer_handle, maxErrorsToShow)
    vim.diagnostic.set(name_space_id, buffer_handle, diagnostics, {virtual_text = true})
    vim.diagnostic.show(name_space_id, buffer_handle)
end

return M