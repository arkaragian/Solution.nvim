-- Code here is based on code found in the following links:
-- Based on https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
-- and https://www.2n.pl/blog/how-to-make-ui-for-neovim-plugins-in-lua
--
-- This file may be abandoned in favor of a plenary.nvim window implementation
-- This file handles a single window
local ui = {}

local buf = -1 -- The buffer that holds the window text.
local border_buf = -1 -- Thee buffer that holds the borders.
local windowHandle -- The handle of the window
local borderWindowHandle

ui.PaintWindow = function(title)

    local listedBuffer = false
    local throwAwayBuffer = true

    -- The window displays a buffer. Thus we construct a buffer where we place
    -- what we want to display. This buffer should not be listed in order to
    -- not polute the userspace with buffernumbers.
    --
    -- Create a buffer that will hold the window contents and the borders.
    buf = vim.api.nvim_create_buf(listedBuffer, throwAwayBuffer)
    border_buf = vim.api.nvim_create_buf(listedBuffer, throwAwayBuffer)

    -- Delete the buffern when it gets hidden
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(border_buf, 'bufhidden', 'wipe')

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

    -- The head line  .. ===Title=== .. can be calculated using the following
    -- logic. Calculate the side width. Then because we divide by int the total
    -- with may not add up to the correct one.
    --
    --TODO handle very large titles by abbreviating them.
    local titleLength = string.len(title)
    local title_side_width = (border_opts.width - titleLength)/2

    -- We may have a floating number here. Convert to integer.
    local left_width = math.floor(title_side_width)
    local right_width = math.floor(title_side_width)

    -- Reconstruct the width to check the legnth
    local total_width = left_width + right_width + titleLength

    --print("Total Width:".. total_width .. " Window:".. border_opts.width)

    if(total_width < border_opts.width) then
        -- Selects where to subtract witdth from.
        local selector = 'R'
        while(total_width < border_opts.width) do
            if (selector == 'R') then
                right_width = right_width +1
                selector = 'L'
            else
                left_width = left_width +1
                selector = 'R'
            end
            total_width = left_width + right_width + titleLength
        end
    end

    if(total_width > border_opts.width) then
        -- Selects where to subtract witdth from.
        local selector = 'R'
        while(total_width > border_opts.width) do
            if (selector == 'R') then
                right_width = right_width -1
                selector = 'L'
            else
                left_width = left_width -1
                selector = 'R'
            end
            total_width = left_width + right_width + titleLength
        end
    end

    local left_side = '╔' .. string.rep('═',left_width-1)
    local right_side = string.rep('═',right_width-1) .. '╗'

    --if(string.len(left_side) ~= left_width) then
    --    print("Left width:" .. string.len(left_side) .. " Expected:".. left_width)
    --end

    --if(string.len(right_side) ~= right_width) then
    --    print("right width:" .. string.len(right_side) .. " Expected:".. right_width)
    --end

    local head_line =  left_side ..  title .. right_side

    -- Generate strings with the borders
    local border_lines = { head_line }
    local middle_line = '║' .. string.rep(' ', win_width) .. '║'
    for i=1, win_height do
        table.insert(border_lines, middle_line)
    end
    table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')

    --Set the content of the border buffer
    vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

    --Second argument indicates that we should enter this buffer
    borderWindowHandle = vim.api.nvim_open_win(border_buf, true, border_opts)
    windowHandle = vim.api.nvim_open_win(buf, true, opts)

    --vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
    --vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..buf)

    -- highlight the line with the cursor
    vim.api.nvim_win_set_option(windowHandle, 'cursorline', true) -- it highlight line with the cursor on it

    -- we can add title already here, because first line will never change
    -- Add thre lines. One for the title, and two gap lines.
    -- ENABLE THIS
    --vim.api.nvim_buf_set_lines(buf, 0, -1, false, { center(title), '', ''})
    --vim.api.nvim_buf_add_highlight(buf, -1, 'WhidHeader', 0, 0, -1)
    print(vim.inspect(vim.api.nvim_list_wins()))
    print("Display:" .. windowHandle)
    print("Border:" .. borderWindowHandle)
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

--- Brings the popup window (if it exists) into keyboard focus.
ui.BringToFront = function()
    if not windowHandle then
        print("No window handle to bring to front")
        return
    end

    if not borderWindowHandle then
        print("No border window handle to bring to front")
        return
    end

    vim.api.nvim_set_current_win(borderWindowHandle)
    vim.api.nvim_set_current_win(windowHandle)
end

--- Closes the window
ui.CloseWindow = function()
    -- When the bufer that contains the window, closes
    -- we have defined a autocommand to close the border buffer also
    if(buf > 1 and windowHandle) then
        vim.keymap.del('n','<ESC>',{buffer = buf})
        vim.keymap.del('n','q',{buffer = buf})
        vim.api.nvim_win_close(windowHandle, true)
        vim.api.nvim_win_close(borderWindowHandle, true)
    end

    -- Since we are closed. Reset our state.
    buf = -1
    border_buf = -1
    borderWindowHandle = nil
    windowHandle = nil
end

--local function move_cursor()
--  local new_pos = math.max(4, vim.api.nvim_win_get_cursor(windowHandle)[1] - 1)
--  vim.api.nvim_win_set_cursor(windowHandle, {new_pos, 0})
--end

local function set_mappings(bufNr)

  vim.keymap.set('n','<ESC>',ui.CloseWindow,{ buffer = bufNr, nowait = true, noremap = true, silent = true })
  vim.keymap.set('n','q',ui.CloseWindow,{ buffer = bufNr, nowait = true, noremap = true, silent = true })

  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    vim.api.nvim_buf_set_keymap(bufNr, 'n', v, '', { nowait = true, noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufNr, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufNr, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

ui.OpenWindow = function(title)
    ui.PaintWindow(title)
    set_mappings(buf)
    --set_mappings(border_buf)
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