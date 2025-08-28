--This is the in game api
local api = require("api")

--This is our UI library
local gui = require("cashmoney/gui")
--This Michaels auction house data
local marketdata = require("your_paystub/data/auction_house_prices")

--Boilerplate for addons
local cashmoney = {
  name = "Cash Money - DEVELOPMENT",
  author = "Zeroun",
  desc = "Materials Calculator",
  version = "0.1"
}


--File paths (define once)
local FILE_ITEM_LIST = "cashmoney\\data\\item_list.lua"
local FILE_DEBUG = "cashmoney\\data\\debug.lua"
--These items will be treated as raw materials
local excludedItems = {
    [28175] = true,  -- Dawn Lake Light Essence
    [27217] = true,  -- Shrimp (if you want to exclude this too)
    [16358] = true,  -- Starlight Archeum Essence
    [16356] = true,  -- Sunlight Archeum Essence
    [16357] = true,  -- Moonlight Archeum Essence
    -- Add more item IDs here as needed
}

local config = {
    excludedItems = excludedItems,
    files = {
        itemList = FILE_ITEM_LIST,
        debug = FILE_DEBUG
    },
    performance = {
        enableApiCacheOptimization = true
    }
}


-- Helper to round and format to exactly 4 decimals
local function format4(num)
    return string.format("%.4f", num or 0)
end


-- DEBUG TOGGLE: Set to true to enable logging, false to disable
local DEBUG_ENABLED = true

-- DEBUG MANAGER: Global function to append debug content to existing file
local function log(content, sessionName)
    if not DEBUG_ENABLED then return end  -- Early exit if logging disabled
    
    -- Echo parameters to in-game log
    --api.Log:Info("==LOG==: \n'" .. tostring(sessionName) .. "', \ncontent='" .. tostring(content) .. "'\n=END LOG=")
    api.Log:Info("[" .. sessionName .. "]: " .. content)
    -- Read existing file (if it doesn't exist, fallback to empty string)
    local existingContent = api.File:Read(FILE_DEBUG) or ""

    -- Format log entry
    local sessionHeader = "\n--- " .. sessionName .. " SESSION ---\n"
    local logEntry = content .. "\n"

    -- Combine old + new
    local newContent = existingContent .. sessionHeader .. logEntry

    -- Write back to file
    api.File:Write(FILE_DEBUG, newContent)

end



-- Dependencies table
local deps = {
    api = api,
    gui = gui,
    marketdata = marketdata,
    config = config,
    log = log,
    format4 = format4
}

--This is called when we click on the OpenSettings button within the addons window
local function OpenSettings()
    -- Log to in-game system log
    api.Log:Info("Opening up addon settings...")

    log("Opening addon settings", "SETTINGS")
    
    -- Actually open the main window
    if MainWindow then
        MainWindow:Open()
    end
end

--Is called when addon is loaded
local function Load() 
    
    MainWindow = require("cashmoney/windows/item_window")(deps)
    --MainWindow:Open()
    --RecipeWindow = require("cashmoney/windows/recipe_window")
    api.Log:Info("[INIT] Addon Loaded!")
    api.File:Write(FILE_DEBUG, "=== CASH MONEY ADDON DEBUG LOG ===\n")

end

-- Unload is called when addons are reloaded.
-- Here you want to destroy your windows and do other tasks you find useful.
local function Unload()
    if MainWindow then
        if MainWindow.Close then
            MainWindow:Close()
        end
        MainWindow = nil
    end
end

-- Here we make sure to bind the functions we defined to our addon. This is how the game knows what function to use!
cashmoney.OnLoad = Load
cashmoney.OnUnload = Unload
cashmoney.OnSettingToggle = OpenSettings

-- Make utility functions globally accessible
-- cashmoney.extractCraftableItems = extractCraftableItems

return cashmoney