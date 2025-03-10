local TestPicker = {}
-- Main module used to create a new picker
local pickers = require("telescope.pickers")

-- Provides interfaces to fill the picker with items.
local finders = require("telescope.finders")

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require('telescope.pickers.entry_display')

--Values table which holds the user's configuration. So to
--make it easier we access this table directly in conf.
local conf = require("telescope.config").values

local SolutionManager = require("solution.SolutionManager")
local TestManager = require("solution.TestManager")

-- TestPicker.Pick = function(opts)
--   opts = opts or {}
--   pickers.new(opts, {
--     prompt_title = "Tests",
--     finder = finders.new_table {
--       -- This works when we load the tests in the start.
--       results = TestManager.GetTestList()
--     },
--     sorter = conf.generic_sorter(opts),
--   }):find()
-- end
--

-- Dynamically calculate the widths for a two collumn picker displpay.
local function calculate_widths()
    local total_width = vim.api.nvim_win_get_width(0) - 10
    local name_width = math.floor(total_width * 0.8)
    local type_width = math.floor(total_width * 0.2)
    return name_width, type_width
end

-- Define the entry display format
local function gen_from_test_name(entry)

    -- TODO: Do not recalculate for every test.
    local name_width, type_width = calculate_widths()

    -- This returns a function that we will use to display our entries
    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = name_width }, -- First column (name)
            { width = type_width }, -- Second column (size)
        }
    })

    return displayer({
        entry, -- This is the test name
        "test",
    })
end

--- Modifies a default telescope entry to display test
local function test_entry_maker(entry)
    -- Assumes entries are simple strings
    return {
        value =  entry,
        display = function(_)
            -- telescope constructs an entry with value ordinal and display. We need the pure value.
            return gen_from_test_name(entry)
        end,
        ordinal = entry,
    }
end

--- Execute a telescope picker for the tests
TestPicker.Pick = function(opts)
    vim.notify("Starting Test Picker", vim.log.levels.INFO , { title = "Solution.nvim" })
    opts = opts or {}

    if TestManager.State.TestListParsingState == "parsing" then
        vim.notify("Test Parsing is not yet ready. Try again later.", vim.log.levels.WARN, { title = "Solution.nvim" })
        return
    end

    if TestManager.State.TestList == nil then
        vim.notify("Tests are nill updating", vim.log.levels.INFO , { title = "Solution.nvim" })
        --- The results that are actually displayed
        local test_results = {}

        -- Create the picker
        local picker = pickers.new(opts, {
            prompt_title = "Tests",
            finder = finders.new_table(
                {
                    results = test_results,
                    entry_maker = test_entry_maker
                }
            ),
            sorter = conf.generic_sorter(opts),
        })

        --- Adds a test to the displayed results
        local function update_picker(test)
            table.insert(test_results, test)
            if picker then
                local input = {
                    results = test_results,
                    entry_maker = test_entry_maker
                }
                picker:refresh(finders.new_table(input), { reset_prompt = false })
            end
        end

        -- Start the picker
        picker:find()

        -- Call GetTests with the update_picker function
        TestManager.GetTests(SolutionManager.Solution.SolutionPath, update_picker)
    else
        vim.notify("Tests are NOT nill", vim.log.levels.INFO , { title = "Solution.nvim" })
        -- print(vim.inspect(TestManager.State.TestList))
        -- Create the picker
        local picker = pickers.new(opts, {
            prompt_title = "Tests",
            -- finder = finders.new_table({ results = TestManager.State.TestList }),
            finder = finders.new_table(
                {
                    results = TestManager.State.TestList,
                    entry_maker = test_entry_maker
                }
            ),
            sorter = conf.generic_sorter(opts),
            -- Handle what to do when we make a chaoice
            attach_mappings = function(prompt_bufnr, map)
                --When we make a selection just close the buffer and
                --assign the result to the
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    --print(vim.inspect(selection))
                    TestManager.State.SelectedTest = selection.value
                    --vim.api.nvim_put({ selection[1] }, "", false, true)
                end)
                return true
            end,
        })

        -- Start the picker
        picker:find()
    end
end

return TestPicker
