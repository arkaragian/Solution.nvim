-- Code here is based on code found in the following links:
-- Based on https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
-- and https://www.2n.pl/blog/how-to-make-ui-for-neovim-plugins-in-lua
--
-- This file may be abandoned in favor of a plenary.nvim window implementation
-- This file handles a single window
local ui = {}

local buf = -1
local windowHandle
local position = 0

local function center(str)
  local width = vim.api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

ui.PaintWindow = function(title)

    local listedBuffer = false
    local throwAwayBuffer = true

    -- The window displays a buffer. Thus we construct a buffer where we place
    -- what we want to display. This buffer should not be listed in order to
    -- not polute the userspace with buffernumbers.
    --
    -- Create a buffer that will hold the window contents and the borders.
    buf = vim.api.nvim_create_buf(listedBuffer, throwAwayBuffer)
    local border_buf = vim.api.nvim_create_buf(false, true)

    -- Delete the buffern when it gets hidden
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'whid')

    -- Get the instance dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    --Window dimensions
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    -- Window Position
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- Options for the border buffer
    local border_opts = {
        style = "minimal",
        relative = "editor",
        width = win_width + 2,
        height = win_height + 2,
        row = row - 1,
        col = col - 1
    }

    -- Options for the actual content buffer
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col
    }

    -- Generate strings with the borders
    local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
    local middle_line = '║' .. string.rep(' ', win_width) .. '║'
    for i=1, win_height do
        table.insert(border_lines, middle_line)
    end
    table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')

    --Set the content of the border buffer
    vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

    --Second argument indicates that we should enter this buffer
    local _ = vim.api.nvim_open_win(border_buf, true, border_opts)
    windowHandle = vim.api.nvim_open_win(buf, true, opts)

    vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

    -- highlight the line with the cursor
    vim.api.nvim_win_set_option(windowHandle, 'cursorline', true) -- it highlight line with the cursor on it

    -- we can add title already here, because first line will never change
    -- Add thre lines. One for the title, and two gap lines.
    -- ENABLE THIS
    --vim.api.nvim_buf_set_lines(buf, 0, -1, false, { center(title), '', ''})
    --vim.api.nvim_buf_add_highlight(buf, -1, 'WhidHeader', 0, 0, -1)
end

--- Adds a line to the current window.
--@param line The line to display
--@param removeCR A boolean option that indicates if a trailing CR should be removed.
ui.AddLine = function(line,removeCR)
    if line and buf > 0 then
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)

        if(removeCR) then
            line = string.gsub(line,"\r","")
        end

        local nuLines = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, nuLines, nuLines+1, false, {line})
        vim.api.nvim_win_set_cursor(windowHandle, {nuLines, 0})

        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    end
end

--- Closes the window
ui.CloseWindow = function()
    -- When the bufer that contains the window, closes
    -- we have defined a autocommand to close the border buffer also
    vim.keymap.del('n','<ESC>',{buffer = buf})
    vim.api.nvim_win_close(windowHandle, true)
    buf = -1
end

local function move_cursor()
  local new_pos = math.max(4, vim.api.nvim_win_get_cursor(windowHandle)[1] - 1)
  vim.api.nvim_win_set_cursor(windowHandle, {new_pos, 0})
end

local function set_mappings(buf)
  local mappings = {
    ['['] = 'update_view(-1)',
    [']'] = 'update_view(1)',
    ['<cr>'] = 'open_file()',
    h = 'update_view(-1)',
    l = 'update_view(1)',
    q = 'close_window()',
    k = 'move_cursor()'
  }

  --for key,val in pairs(mappings) do
  --  vim.api.nvim_buf_set_keymap(buf, 'n', key, ':lua require"whid".'..val..'<cr>', {
  --      nowait = true, noremap = true, silent = true
  --    })
  --end

  vim.keymap.set('n','<ESC>',ui.CloseWindow,{ buffer = buf, nowait = true, noremap = true, silent = true })
  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    vim.api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

ui.OpenWindow = function(title)
    ui.PaintWindow(title)
    set_mappings(buf)
    -- This works for a single line
    --vim.api.nvim_buf_set_lines(buf, 1, 2, false, {center("A Sample Line")})
    --vim.api.nvim_win_set_cursor(windowHandle,{1,2})
end

--ui.whid = function()
--    position = 0
--    ui.open_window()
--    set_mappings()
--    update_view(0)
--    api.nvim_win_set_cursor(win, {4, 0})
--end

---return {
---  whid = whid,
---  update_view = update_view,
---  open_file = open_file,
---  move_cursor = move_cursor,
---  close_window = close_window
---}


return ui
