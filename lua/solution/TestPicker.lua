local TestPicker = {}
-- Main module used to create a new picker
local pickers = require("telescope.pickers")

-- Provides interfaces to fill the picker with items.
local finders = require("telescope.finders")

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

--- Execute a telescope picker for the tests
TestPicker.Pick = function(opts)
    opts = opts or {}

    if (TestManager.State.TestListParsingState == "parsing") then
        vim.notify("Test Parsing is not yet ready. Try again later.", vim.log.levels.WARN, { title = "Solution.nvim" })
        return
    end

    if (TestManager.State.TestList == nil) then
        --- The results that are actually displayed
        local test_results = {}

        -- Create the picker
        local picker = pickers.new(opts, {
                prompt_title = "Tests",
                finder = finders.new_table { results = test_results },
                sorter = conf.generic_sorter(opts),
            })

        --- Adds a test to the displayed results
        local function update_picker(test)
            table.insert(test_results, test)
            if picker then
                picker:refresh(finders.new_table { results = test_results }, { reset_prompt = false })
            end
        end

        -- Start the picker
        picker:find()

        -- Call GetTests with the update_picker function
        TestManager.GetTests(SolutionManager.Solution.SolutionPath, update_picker)
    else
        -- Create the picker
        local picker = pickers.new(opts, {
                prompt_title = "Tests",
                finder = finders.new_table { results = TestManager.State.TestList },
                sorter = conf.generic_sorter(opts),
            })

        -- Start the picker
        picker:find()
    end
end


return TestPicker
