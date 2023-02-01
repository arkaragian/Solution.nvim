--See https://paulwatt526.github.io/wattageTileEngineDocs/luaOopPrimer.html

local Window = {}

function Window.new (Title)
    local self = {}

    local listedBuffer = false
    local throwAwayBuffer = true
    --
    -- Public Properties
    self.BufferNumber = vim.api.nvim_create_buf(listedBuffer, throwAwayBuffer)
    self.BorderBufferNumber = vim.api.nvim_create_buf(listedBuffer, throwAwayBuffer)

    -- Delete the buffer when it gets hidden
    vim.api.nvim_buf_set_option(self.BufferNumber, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(self.BorderBufferNumber, 'bufhidden', 'wipe')

    self.WindowHandle = nil
    self.BorderWindowHandle = nil
    self.Title = Title



    -- Get the instance dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    --Window dimensions
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    -- Window Position
    local win_row = math.ceil((height - win_height) / 2 - 1)
    local win_col = math.ceil((width - win_width) / 2)

    -- The names of the options are not chosen by the author. Instead they are
    -- the names are that are needed by the vim window open function. Same goes
    -- with the values of style and relative
    self.BorderWindowOptions = {
        style = "minimal",
        relative = "editor",
        width = win_width+2,
        height = win_height+2,
        row = win_row-1,
        col = win_col-1,
    }

    self.WindowOptions = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = win_row,
        col = win_col,
    }
    --------------------------------------------------------------------------
    --                 P r i v a t e   F u n c t i o n s                    --
    --------------------------------------------------------------------------
    -- As a conventions in the vim lua ecosystem all private functions are
    -- prefixed with an underscore (_)
    --------------------------------------------------------------------------

    local function _SetMappings()
        local bufNr = self.BufferNumber

        vim.keymap.set('n','<ESC>',function() Window.CloseWindow(self) end,{ buffer = bufNr, nowait = true, noremap = true, silent = true })
        vim.keymap.set('n','q',function() Window.CloseWindow(self) end,{ buffer = bufNr, nowait = true, noremap = true, silent = true })

        local other_chars = {
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
        }
        for k,v in ipairs(other_chars) do
            -- Disable char char(uppercase) as well as Ctrl+char
            vim.api.nvim_buf_set_keymap(bufNr, 'n', v, '', { nowait = true, noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufNr, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufNr, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
        end
    end

    --------------------------------------------------------------------------
    --                  P u b l i c  F u n c t i o n s                      --
    --------------------------------------------------------------------------
    function self.SetWidth(w)
        self.BorderWindowOptions.Width = w
    end

    -- Public Functions
    function self.SetHeight(h)
        self.BorderWindowOptions.Height = h
    end

    -- Public Functions
    function self.SetBorderOptions(o)
        self.BorderOptionst = o
    end

    function self.Close()
        Window.CloseWindow(self)
    end

    function self.PaintWindow()

        -- The head line  .. ===Title=== .. can be calculated using the following
        -- logic. Calculate the side width. Then because we divide by int the total
        -- with may not add up to the correct one.
        --
        --TODO handle very large titles by abbreviating them.
        local titleLength = string.len(self.Title)
        local title_side_width = (self.BorderWindowOptions.width - titleLength)/2

        -- We may have a floating number here. Convert to integer.
        local left_width = math.floor(title_side_width)
        local right_width = math.floor(title_side_width)

        -- Reconstruct the width to check the legnth
        local total_width = left_width + right_width + titleLength

        --print("Total Width:".. total_width .. " Window:".. border_opts.width)

        if(total_width < self.BorderWindowOptions.width) then
            -- Selects where to subtract witdth from.
            local selector = 'R'
            while(total_width < self.BorderWindowOptions.width) do
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

        if(total_width > self.BorderWindowOptions.width) then
            -- Selects where to subtract witdth from.
            local selector = 'R'
            while(total_width > self.BorderWindowOptions.width) do
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

        local head_line =  left_side ..  self.Title .. right_side

        -- Generate strings with the borders
        local border_lines = { head_line }
        local middle_line = '║' .. string.rep(' ', win_width) .. '║'
        for i=1, win_height do
            table.insert(border_lines, middle_line)
        end
        table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')

        --Set the content of the border buffer
        vim.api.nvim_buf_set_lines(self.BorderBufferNumber, 0, -1, false, border_lines)

        --Second argument indicates that we should enter this buffer
        self.BorderWindowHandle = vim.api.nvim_open_win(self.BorderBufferNumber, true, self.BorderWindowOptions)
        self.WindowHandle = vim.api.nvim_open_win(self.BufferNumber, true, self.WindowOptions)

        --vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
        --vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..buf)

        -- highlight the line with the cursor
        vim.api.nvim_win_set_option(self.WindowHandle, 'cursorline', true) -- it highlight line with the cursor on it

        -- Set the window mappings
        _SetMappings()
    end


    --- Adds a line to the current window.
    --@param line The line to display
    --@param removeCR A boolean option that indicates if a trailing CR should be removed.
    function self.AddLine(line,removeCR)
        if not line then
            return
        end

        if(self.BufferNumber == nil) then
            return
        end

        if(self.BufferNumber < 0) then
            return
        end

        if(self.WindowHandle == nil) then
            return
        end

        if(self.WindowHandle < 0) then
            return
        end

        vim.api.nvim_buf_set_option(self.BufferNumber, 'modifiable', true)

        if(removeCR) then
            line = string.gsub(line,"\r","")
        end

        local nuLines = vim.api.nvim_buf_line_count(self.BufferNumber)
        -- Append line
        vim.api.nvim_buf_set_lines(self.BufferNumber, nuLines, nuLines+1, false, {line})
        -- Move cursor to the final line
        vim.api.nvim_win_set_cursor(self.WindowHandle, {nuLines, 0})
        --Make buffer not modifiable again
        vim.api.nvim_buf_set_option(self.BufferNumber, 'modifiable', false)

    end


    --- Brings the popup window (if it exists) into keyboard focus.
    function self.BringToFront()
        vim.api.nvim_set_current_win(self.BorderWindowHandle)
        vim.api.nvim_set_current_win(self.WindowHandle)
    end


    return self
end


------------------------------------------------------------------------------
--                  S t a t i c  F u n c t i o n s                          --
------------------------------------------------------------------------------
Window.CloseWindow = function(theWindow)

    if(theWindow.BufferNumber == nil) then
        return
    end

    if(theWindow.BufferNumber < 0) then
        return
    end

    if(theWindow.WindowHandle == nil) then
        return
    end

    if(theWindow.WindowHandle < 0) then
        return
    end
    -- When the bufer that contains the window, closes
    -- we have defined a autocommand to close the border buffer also
    vim.keymap.del('n','<ESC>',{buffer = theWindow.BufferNumber})
    vim.keymap.del('n','q',{buffer =theWindow.BufferNumber})
    vim.api.nvim_win_close(theWindow.WindowHandle, true)
    vim.api.nvim_win_close(theWindow.BorderWindowHandle, true)

    -- Since we are closed. Reset our state.
    --buf = -1
    --border_buf = -1
    --borderWindowHandle = nil
    --windowHandle = nil
end


return Window
