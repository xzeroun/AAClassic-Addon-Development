-- Script to extract only craftable items from the full item list
-- This will create a new lua table with only items that have crafting recipes

local api = require("api")

-- Load the full item data
local allItems = require("cashmoney/data/item_id_to_name")

-- Table to store craftable items
local craftableItems = {}

-- Counter for progress tracking
local totalItems = 0
local craftableCount = 0

-- Count total items first
for _ in pairs(allItems) do
    totalItems = totalItems + 1
end

api.Log:Info("Starting craftable item extraction...")
api.Log:Info("Total items to check: " .. totalItems)

-- Iterate through all items and check if they're craftable
for itemId, itemName in pairs(allItems) do
    -- Check if this item has a crafting recipe
    local craftType = api.Craft:GetCraftTypeByItemType(itemId)
    
    if craftType then
        -- This item is craftable, add it to our table
        craftableItems[itemId] = itemName
        craftableCount = craftableCount + 1
        
        -- Log progress every 100 craftable items found
        if craftableCount % 100 == 0 then
            api.Log:Info("Found " .. craftableCount .. " craftable items so far...")
        end
    end
end

api.Log:Info("Extraction complete!")
api.Log:Info("Found " .. craftableCount .. " craftable items out of " .. totalItems .. " total items")

-- Convert the table to a Lua file format
local function tableTolua(tbl)
    local result = "-- Auto-generated craftable items only\n"
    result = result .. "-- Items that have crafting recipes in ArcheAge Classic\n"
    result = result .. "-- Total craftable items: " .. craftableCount .. "\n"
    result = result .. "return {\n"
    
    -- Sort by ID for cleaner output
    local sortedIds = {}
    for id in pairs(tbl) do
        table.insert(sortedIds, id)
    end
    table.sort(sortedIds)
    
    for _, id in ipairs(sortedIds) do
        local name = tbl[id]
        -- Escape quotes in the name
        local escapedName = name:gsub('"', '\\"')
        result = result .. string.format('    [%d] = "%s",\n', id, escapedName)
    end
    
    result = result .. "}\n"
    return result
end

-- Write the craftable items to a new file
local craftableItemsLua = tableTolua(craftableItems)
local success = api.File:Write("cashmoney\\data\\craftable_items.lua", craftableItemsLua)

if success then
    api.Log:Info("Successfully wrote craftable items to cashmoney\\data\\craftable_items.lua")
    api.Log:Info("Usage: local craftableItems = require('cashmoney/data/craftable_items')")
else
    api.Log:Info("Failed to write craftable items file!")
end