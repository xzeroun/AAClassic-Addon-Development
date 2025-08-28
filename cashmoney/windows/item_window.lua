local api = require("api")
-- item_window.lua
return function(deps)
    -- Extract all dependencies
    local api = deps.api
    local gui = deps.gui
    local marketdata = deps.marketdata
    local config = deps.config
    local log = deps.log
    local format4 = deps.format4

    local window = {}
    local mainWindow = nil  -- Store the actual UI window
    local cachedItemList = nil  -- Cache the item list in memory to work around file read issues
    local processedItemData = nil  -- Store fully processed item data for UI
    
    
    -- Item lookup cache
    local itemLookupTable = nil
    local reverseItemLookup = nil
    
    -- Helper function to count table entries
    local function table_count(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
    
    -- ULTRA-EFFICIENT: Single function that processes everything with minimal API calls - This grabs everything we need from the api for a specific item
    -- local function ProcessItemComplete(itemId, quantity, existingBuyPrefs, debugMode)
    --     quantity = quantity or 1
    --     existingBuyPrefs = existingBuyPrefs or {}
    --     debugMode = debugMode or false
        
    --     local apiCache = {}  -- Cache all API results to prevent duplicate calls
    --     local processedItems = {}  -- Track what we've fully processed
        
    --     -- Helper: Get all item data with single API call per item
    --     local function getItemData(id)
    --         if apiCache[id] then return apiCache[id] end
            
    --         -- Single batch of API calls per item
    --         local itemInfo = api.Item:GetItemInfoByType(id)
    --         if not itemInfo then return nil end
            
    --         local craftType = api.Craft:GetCraftTypeByItemType(id)
    --         local craftBaseInfo = craftType and api.Craft:GetCraftBaseInfo(craftType)
    --         local materialsInfo = craftType and api.Craft:GetCraftMaterialInfo(craftType)
            
    --         local marketPrice = marketdata[id] and marketdata[id].average or 0
            
    --         -- Process materials list
    --         local materials = {}
    --         if materialsInfo then
    --             for i, matData in pairs(materialsInfo) do
    --                 if matData.item_info and matData.item_info.itemType ~= 500 then
    --                     materials[matData.item_info.itemType] = {
    --                         name = matData.item_info.name,
    --                         amount = matData.amount
    --                     }
    --                 end
    --             end
    --         end
            
    --         -- Cache everything from this single API batch
    --         apiCache[id] = {
    --             id = id,
    --             name = itemInfo.name,
    --             category = itemInfo.category,
    --             marketPrice = marketPrice,
    --             isCraftable = craftType ~= nil,
    --             laborCost = craftBaseInfo and craftBaseInfo.consume_lp or 0,
    --             workbench = (craftBaseInfo and craftBaseInfo.doodad_name) and craftBaseInfo.doodad_name or "Default",
    --             materials = materials,
    --             isExcluded = config.excludedItems[id] or false
    --         }
            
    --         return apiCache[id]
    --     end
        
    --     -- Recursive processor that builds complete structure + calculates costs
    --     local function processRecursive(id, qty, level, visited)
    --         level = level or 0
    --         visited = visited or {}
            
    --         if visited[id] then return 0, 0 end  -- Prevent loops
    --         if id == 500 then return 0, 0 end   -- Skip coins
            
    --         visited[id] = true
    --         local indent = string.rep("  ", level)
            
    --         -- Get cached data (single API call per item across entire tree)
    --         local itemData = getItemData(id)
    --         if not itemData then 
    --             visited[id] = nil
    --             return 0, 0 
    --         end
            
    --         if debugMode then
    --             -- indent .. "Processing: " .. itemData.name .. " (qty: " .. qty .. ")", "PROCESS")
    --         end
            
    --         -- If excluded, not craftable, or marked as "buy" - use market price
    --         local shouldBuy = existingBuyPrefs[id] or itemData.isExcluded or not itemData.isCraftable
    --         if shouldBuy then
    --             if debugMode then
    --                 -- indent .. "Buying - no labor, market cost: " .. itemData.marketPrice * qty, "PROCESS")
    --             end
    --             visited[id] = nil
    --             return 0, itemData.marketPrice * qty
    --         end
            
    --         -- Calculate crafting: item labor + material costs
    --         local itemLabor = itemData.laborCost * qty
    --         local totalChildLabor = 0
    --         local totalMaterialCost = 0
            
    --         if debugMode then
    --             -- indent .. "Crafting - item labor: " .. itemLabor, "PROCESS")
    --         end
            
    --         -- Process all materials recursively
    --         for matId, matInfo in pairs(itemData.materials) do
    --             local matQty = matInfo.amount * qty
    --             local childLabor, childCost = processRecursive(matId, matQty, level + 1, visited)
    --             totalChildLabor = totalChildLabor + childLabor
    --             totalMaterialCost = totalMaterialCost + childCost
                
    --             if debugMode then
    --                 -- indent .. "  Mat: " .. matInfo.name .. " -> Labor: " .. childLabor .. ", Cost: " .. childCost, "PROCESS")
    --             end
    --         end
            
    --         local totalLabor = itemLabor + totalChildLabor
    --         if debugMode then
    --             -- indent .. "Total - Labor: " .. totalLabor .. ", Cost: " .. totalMaterialCost, "PROCESS")
    --         end
            
    --         visited[id] = nil
    --         return totalLabor, totalMaterialCost
    --     end
        
    --     -- Process the main item
    --     local totalLabor, totalCost = processRecursive(itemId, quantity, 0, {})
    --     local mainItemData = getItemData(itemId)
        
    --     if not mainItemData then return nil end
        
    --     -- Build complete recipe structure using cached data
    --     local recipeStructure = {
    --         workbenches = {
    --             recipe1 = {
    --                 workbench = mainItemData.workbench,
    --                 laborCost = mainItemData.laborCost,
    --                 default = true,
    --                 materials = {}
    --             }
    --         }
    --     }
        
    --     -- Add materials with buy preferences
    --     for matId, matInfo in pairs(mainItemData.materials) do
    --         recipeStructure.workbenches.recipe1.materials[matId] = {
    --             name = matInfo.name,
    --             amount = matInfo.amount,
    --             buy = existingBuyPrefs[matId] or false
    --         }
    --     end
        
    --     -- Return complete item data
    --     return {
    --         laborCost = totalLabor,
    --         name = mainItemData.name,
    --         cost = totalCost,
    --         id = itemId,
    --         value = mainItemData.marketPrice * quantity,
    --         profit = (mainItemData.marketPrice * quantity) - totalCost,
    --         recipes = recipeStructure
    --     }, apiCache  -- Also return cache for potential reuse
    -- end

    -- Combined item lookup system on the main window
    local function GetItemByNameOrId(input, operation)
        -- Nested function: Load item lookup table
        local function loadLookupTable()
            if itemLookupTable then return end -- Already loaded
            
            -- "Loading item lookup table", "ITEM_LOOKUP")
            itemLookupTable = require("cashmoney/data/item_id_to_name")
            
            -- Build reverse lookup (name -> id) for search functionality
            reverseItemLookup = {}
            for id, name in pairs(itemLookupTable) do
                reverseItemLookup[string.lower(name)] = id
            end
            
            -- "Loaded " .. table_count(itemLookupTable) .. " items in lookup table", "ITEM_LOOKUP")
        end
        
        -- Nested function: Get item name by ID
        local function getNameById(itemId)
            loadLookupTable()
            return itemLookupTable[itemId]
        end
        
        -- Nested function: Get item ID by exact name
        local function getIdByName(itemName)
            loadLookupTable()
            return reverseItemLookup[string.lower(itemName)]
        end
        
        -- Nested function: Find items by partial name match or ID
        local function findByPartialName(searchTerm)
            loadLookupTable()
            local exactMatches = {}
            local partialMatches = {}
            
            -- Check if search term is a number (ID search)
            local searchId = tonumber(searchTerm)
            if searchId then
                -- Search by ID
                local itemName = itemLookupTable[searchId]
                if itemName then
                    table.insert(exactMatches, {id = searchId, name = itemName, priority = 1})
                end
            else
                -- Search by name
                local lowerSearchTerm = string.lower(searchTerm)
                
                for name, id in pairs(reverseItemLookup) do
                    if name == lowerSearchTerm then
                        -- Exact match - highest priority
                        table.insert(exactMatches, {id = id, name = itemLookupTable[id], priority = 1})
                    elseif string.find(name, lowerSearchTerm) then
                        -- Partial match - lower priority
                        table.insert(partialMatches, {id = id, name = itemLookupTable[id], priority = 2})
                    end
                end
            end
            
            -- Sort exact matches by name
            table.sort(exactMatches, function(a, b) return a.name < b.name end)
            
            -- Sort partial matches by name
            table.sort(partialMatches, function(a, b) return a.name < b.name end)
            
            -- Combine with exact matches first
            local allMatches = {}
            for _, match in ipairs(exactMatches) do
                table.insert(allMatches, match)
            end
            for _, match in ipairs(partialMatches) do
                table.insert(allMatches, match)
            end
            
            return allMatches
        end
        
        -- Main logic based on operation
        if operation == "get_name" then
            return getNameById(input)
        elseif operation == "get_id" then
            return getIdByName(input)
        elseif operation == "search" then
            return findByPartialName(input)
        elseif operation == "best_match" then
            local matches = findByPartialName(input)
            return (#matches > 0) and matches[1] or nil
        elseif operation == "resolve" then
            -- Resolve name or ID to an ID
            if type(input) == "number" then
                return input
            else
                local itemId = getIdByName(input)
                if not itemId then
                    -- "Item not found: " .. input, "ITEM_RESOLVE_ERROR")
                    api.Log:Info("Item not found: " .. input)
                    return nil
                end
                return itemId
            end
        end
        
        return nil
    end

    -- Simple function to get fresh market data
    local function ReadMarketData(item, marketdata)
        local freshMarketValue = marketdata[item.id] and marketdata[item.id].average or 0
        local freshCost = item.cost or 0
        local freshProfit = freshMarketValue - freshCost
        
        return freshCost, freshMarketValue, freshProfit
    end

    -- Display recipe tree function - receives item data directly (no file reads)
    local function DisplayRecipeTree(itemId, itemData)
        -- Helper function for table counting
        local function table_count(t)
            local count = 0
            for _ in pairs(t) do count = count + 1 end
            return count
        end
        
        -- log("DisplayRecipeTree called for item ID: " .. itemId, "RECIPE_DISPLAY")
        
        -- PHASE 3.5: Use passed item data directly (zero API calls!)
        log("PHASE3.5: Using passed item data directly - no file reads needed!", "PHASE3_FINAL")
        
        if not itemData then
            log("PHASE3.5: ERROR - No item data passed to DisplayRecipeTree", "PHASE3_FINAL")
            return
        end
        
        local targetItem = itemData
        log("PHASE3.5: Target item: " .. targetItem.name .. " (dependencies: " .. (targetItem.dependencies and table_count(targetItem.dependencies) or 0) .. ")", "PHASE3_FINAL")
        
        -- Log basic item info
        -- log("Found item: " .. (targetItem.name or "Unknown") .. " (ID: " .. itemId .. ")", "RECIPE_DISPLAY")
        -- log("Cost: " .. (targetItem.cost or 0) .. ", Value: " .. (targetItem.value or 0), "RECIPE_DISPLAY")
        -- log("Workbench: " .. (targetItem.workbench or "Default"), "RECIPE_DISPLAY")
        
        -- Log materials if they exist
        if targetItem.materials then
            -- log("Direct materials:", "RECIPE_DISPLAY")
            for materialKey, materialData in pairs(targetItem.materials) do
                -- log("  " .. materialKey .. ": " .. (materialData.name or "Unknown") .. " x" .. (materialData.amount or 1), "RECIPE_DISPLAY")
            end
        else
            -- log("No direct materials found", "RECIPE_DISPLAY")
        end
        
        -- Log dependencies if they exist  
        -- log("Checking dependencies...", "RECIPE_DISPLAY")
        if targetItem.dependencies then
            -- log("Dependencies found", "RECIPE_DISPLAY")
            local depCount = 0
            for depKey, depData in pairs(targetItem.dependencies) do
                depCount = depCount + 1
                -- log("  " .. depKey .. ": " .. (depData.name or "Unknown"), "RECIPE_DISPLAY")
            end
            -- log("Total dependencies: " .. depCount, "RECIPE_DISPLAY")
        else
            -- log("No dependencies found", "RECIPE_DISPLAY")
        end
        -- log("Dependencies check complete", "RECIPE_DISPLAY")
        
        -- Create simple recipe window
        -- log("Creating simple recipe window", "RECIPE_DISPLAY")
        local recipeWindow = api.Interface:CreateWindow("RecipeWindow", "Recipe: " .. (targetItem.name or "Unknown"), 900, 600)
        if not recipeWindow then
            -- log("ERROR: Failed to create recipe window", "RECIPE_DISPLAY")
            return
        end
        -- log("Recipe window created successfully", "RECIPE_DISPLAY")
        
        recipeWindow:AddAnchor("CENTER", "UIParent", 0, 0)
        recipeWindow:SetCloseOnEscape(true)
        recipeWindow:Show(true)
        -- log("Recipe window anchored and shown", "RECIPE_DISPLAY")
        
        -- PHASE 2: Build tiered recipe data from existing dependencies structure
        local recipeData = {}
        
        log("PHASE2: Using dependencies structure instead of recursive building", "PHASE2_PERF")
        log("PHASE2: Dependencies available: " .. (targetItem.dependencies and table_count(targetItem.dependencies) or 0), "PHASE2_PERF")
        
        -- PHASE 2: Direct structure conversion function
        local function buildFromDependencies()
            -- Add main item at tier 0
            table.insert(recipeData, {
                id = targetItem.id,
                name = targetItem.name or "Unknown",
                amount = 1,
                tier = 0,
                tierLevel = 0,
                workbench = targetItem.workbench or "Default",
                type = "Main Item",
                buy = false,
                expanded = true,
                laborCost = targetItem.laborCost or 0
            })
            
            log("PHASE2: Added main item: " .. targetItem.name, "PHASE2_PERF")
            
            -- Add all dependencies as materials with calculated tiers
            if targetItem.dependencies then
                for depKey, depData in pairs(targetItem.dependencies) do
                    -- Extract tier information from dependency structure or calculate it
                    local tier = 1 -- Default tier for now, we'll improve this
                    
                    table.insert(recipeData, {
                        id = depData.id,
                        name = depData.name or "Unknown",
                        amount = 1, -- We'll need to calculate proper amounts
                        tier = tier,
                        tierLevel = tier,
                        workbench = depData.workbench or "Default",
                        type = "Material",
                        buy = false,
                        expanded = true,
                        laborCost = depData.laborCost or 0
                    })
                end
                
                log("PHASE2: Added " .. table_count(targetItem.dependencies) .. " dependencies as materials", "PHASE2_PERF")
            end
        end
        
        -- PHASE 3: Recursive function with no external data dependencies
        local function addItemToTier(item, amount, tier, processedItems)
            processedItems = processedItems or {}
            
            -- Prevent infinite recursion
            local itemKey = item.id .. "_" .. tier
            if processedItems[itemKey] then
                return
            end
            processedItems[itemKey] = true
            
            -- Add current item to recipe data
            table.insert(recipeData, {
                id = item.id,
                name = item.name or "Unknown",
                amount = amount,
                tier = tier,
                tierLevel = tier,  -- Alias for compatibility
                workbench = item.workbench or "Default",
                type = tier == 0 and "Main Item" or "Material",
                buy = false,  -- Default to craft
                expanded = tier == 0 or true,  -- Main item always expanded, craft items start expanded
                laborCost = item.laborCost or 0  -- Include labor cost for display
            })
            
            -- Add materials recursively
            if item.materials then
                for materialKey, materialData in pairs(item.materials) do
                    if materialData.id then
                        -- PHASE 3: Use dependencies exclusively (no fallbacks)
                        local materialItem = nil
                        
                        log("PHASE3: Getting material ID " .. materialData.id .. " from dependencies only", "PHASE3_CLEAN")
                        
                        -- Get material directly from dependencies structure
                        if targetItem.dependencies then
                            local depKey = "id_" .. materialData.id
                            materialItem = targetItem.dependencies[depKey]
                            if materialItem then
                                log("PHASE3: Found " .. materialData.name .. " in dependencies", "PHASE3_CLEAN")
                            else
                                log("PHASE3: Material " .. materialData.name .. " not found in dependencies - creating raw material", "PHASE3_CLEAN")
                            end
                        else
                            log("PHASE3: No dependencies structure available", "PHASE3_CLEAN")
                        end
                        
                        -- Only fallback: create basic raw material (for excluded items)
                        if not materialItem then
                            materialItem = {
                                id = materialData.id,
                                name = materialData.name or ("Item " .. materialData.id),
                                workbench = "Raw Material",
                                laborCost = 0
                            }
                            log("PHASE3: Created basic raw material for " .. materialItem.name, "PHASE3_CLEAN")
                        end
                        
                        -- Recursively add this material
                        addItemToTier(materialItem, materialData.amount * amount, tier + 1, processedItems)
                    end
                end
            end
        end
        
        -- PHASE 3: Use dependencies exclusively (no external data needed)
        log("PHASE3: Starting clean recipe tree build (dependencies only)", "PHASE3_CLEAN")
        addItemToTier(targetItem, 1, 0, nil)
        
        -- Function to check if an item has actual children in the recipe data
        local function itemHasChildren(itemId, itemTier)
            -- Find the item's position in recipeData
            local itemIndex = nil
            for i, recipeItem in ipairs(recipeData) do
                if recipeItem.id == itemId and recipeItem.tier == itemTier then
                    itemIndex = i
                    break
                end
            end
            
            if not itemIndex then return false end
            
            -- Check if there are any items immediately following this one with a higher tier
            for i = itemIndex + 1, #recipeData do
                local potentialChild = recipeData[i]
                
                -- If we hit an item at same or lower tier, no more children
                if potentialChild.tier <= itemTier then
                    return false
                end
                
                -- If we find an item at exactly the next tier level, it's a direct child
                if potentialChild.tier == itemTier + 1 then
                    return true
                end
            end
            
            return false
        end
        
        log("Built simple recipe data with " .. #recipeData .. " items", "RECIPE_DISPLAY")
        
        -- Calculate initial total labor cost
        --log("=== CALCULATING INITIAL TOTAL LABOR ===", "INITIAL_LABOR")
        local initialTotalLabor = 0
        
        -- Sum up all labor costs from all items (initially all are craft since buy defaults to false)
        for i, item in ipairs(recipeData) do
            local shouldCountLabor = true
            
            -- Check if this item should be counted (initially no ancestors are "buy")
            if item.tier > 0 then
                for checkTier = item.tier - 1, 0, -1 do
                    local ancestorAtTier = nil
                    
                    for parentIndex = i - 1, 1, -1 do
                        local potentialAncestor = recipeData[parentIndex]
                        if potentialAncestor.tier == checkTier then
                            ancestorAtTier = potentialAncestor
                            break
                        end
                    end
                    
                    if ancestorAtTier and ancestorAtTier.buy then
                        shouldCountLabor = false
                        break
                    end
                end
            end
            
            if shouldCountLabor then
                local itemLabor = 0
                if not item.buy then
                    -- PHASE 3.6: Use existing labor cost data for all tiers (no API calls!)
                    local baseLabor = item.laborCost or 0
                    local amount = item.amount or 1
                    itemLabor = baseLabor * amount
                    log("PHASE3.6: Labor calc using existing data for " .. item.name .. " - labor=" .. itemLabor, "PHASE3_FINAL")
                end
                initialTotalLabor = initialTotalLabor + itemLabor
                --log("Item " .. item.name .. " (tier " .. item.tier .. ") - labor=" .. itemLabor, "INITIAL_LABOR")
            end
        end
        
        -- Calculate initial total cost (materials)
        log("=== CALCULATING INITIAL TOTAL COST ===", "INITIAL_COST")
        local initialTotalCost = 0
        
        -- Sum up all material costs from all items (initially all are craft since buy defaults to false)
        for i, item in ipairs(recipeData) do
            local shouldCountCost = true
            
            -- Check if this item should be counted (initially no ancestors are "buy")
            if item.tier > 0 then
                for checkTier = item.tier - 1, 0, -1 do
                    local ancestorAtTier = nil
                    
                    for parentIndex = i - 1, 1, -1 do
                        local potentialAncestor = recipeData[parentIndex]
                        if potentialAncestor.tier == checkTier then
                            ancestorAtTier = potentialAncestor
                            break
                        end
                    end
                    
                    if ancestorAtTier and ancestorAtTier.buy then
                        shouldCountCost = false
                        break
                    end
                end
            end
            
            if shouldCountCost then
                local itemCost = 0
                if item.buy then
                    -- If buying, use market price
                    local marketPrice = marketdata[item.id] and marketdata[item.id].average or 0
                    local amount = item.amount or 1
                    itemCost = marketPrice * amount
                    log("COST CALC: Buying " .. item.name .. " - cost=" .. itemCost .. " (price=" .. marketPrice .. ", amount=" .. amount .. ")", "INITIAL_COST")
                end
                initialTotalCost = initialTotalCost + itemCost
                --log("Item " .. item.name .. " (tier " .. item.tier .. ") - cost=" .. itemCost, "INITIAL_COST")
            end
        end
        
        log("Initial total cost: " .. initialTotalCost, "INITIAL_COST")
        
        -- Set the total labor and cost on the main item (tier 0)
        for i, item in ipairs(recipeData) do
            if item.tier == 0 then
                item.totalLaborCost = initialTotalLabor
                item.totalMaterialCost = initialTotalCost
                --log("Set initial tier 0 total labor cost to: " .. initialTotalLabor, "INITIAL_LABOR")
                log("Set initial tier 0 total material cost to: " .. initialTotalCost, "INITIAL_COST")
                break
            end
        end
        
        --log("=== INITIAL LABOR CALCULATION COMPLETE ===", "INITIAL_LABOR")
        
        -- Simple columns
        local columns = {
            {
                name = "Tier",
                width = 40,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(tostring(rowData.tier or 0))
                    end
                end
            },
            {
                name = "Name",
                width = 400,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        -- Create indented display name based on tier level
                        local indent = string.rep("        ", rowData.tier or 0)  -- 6 spaces per tier level
                        local displayName = rowData.name
                        
                        -- Add expand/collapse indicators for items with children
                        if not rowData.buy and itemHasChildren(rowData.id, rowData.tier) then
                            -- Show expansion state for items that actually have children
                            if rowData.expanded then
                                displayName = "[-] " .. displayName
                            else
                                displayName = "[+] " .. displayName
                            end
                        end
                        
                        -- Add buy/craft status after the item name
                        if rowData.buy then
                            displayName = displayName .. " [BUY]"
                        -- else
                        --     displayName = displayName .. " [CRAFT]"
                        end
                        
                        local fullDisplayName = indent .. displayName
                        subItem:SetText(fullDisplayName)
                        
                        -- Apply color based on buy/craft status
                        local color = rowData.buy and FONT_COLOR.GREEN or FONT_COLOR.RED
                        ApplyTextColor(subItem, color)
                        
                        -- Force left alignment to make indentation visible
                        if subItem.style and subItem.style.SetAlign then
                            subItem.style:SetAlign(ALIGN.LEFT)
                        end
                    end
                    
                    -- Store rowData properties on the subItem for click handler access
                    subItem.itemData = {
                        id = rowData.id,
                        name = rowData.name,
                        tier = rowData.tier,
                        expanded = rowData.expanded,
                        buy = rowData.buy,
                        amount = rowData.amount,
                        laborCost = rowData.laborCost
                    }
                    
                    -- Add click handler for expand/collapse
                    if not subItem.OnClick then
                        subItem.OnClick = function(self, mouseButton)
                            if mouseButton == "LeftButton" then
                                --log("=== CLICKED ITEM DETAILS ===", "PHASE1")
                                --log("ID: " .. tostring(self.itemData.id), "PHASE1")
                                --log("Name: " .. tostring(self.itemData.name), "PHASE1") 
                                --log("Tier: " .. tostring(self.itemData.tier), "PHASE1")
                                -- log("Expanded: " .. tostring(self.itemData.expanded), "PHASE1")
                                -- log("Buy: " .. tostring(self.itemData.buy), "PHASE1")
                                -- log("Amount: " .. tostring(self.itemData.amount), "PHASE1")
                                -- log("Labor Cost: " .. tostring(self.itemData.laborCost), "PHASE1")
                                -- log("=== END CLICKED DETAILS ===", "PHASE1")
                                
                                -- PHASE 2: Find and toggle in recipeData
                                --log("=== SEARCHING FOR ORIGINAL ITEM ===", "PHASE2")
                                for i, originalItem in ipairs(recipeData) do
                                    if originalItem.id == self.itemData.id and originalItem.tier == self.itemData.tier then
                                        --log("Found original item at index " .. i, "PHASE2")
                                        --log("Original expanded state: " .. tostring(originalItem.expanded), "PHASE2")
                                        
                                        -- Toggle the expanded state
                                        originalItem.expanded = not originalItem.expanded
                                        
                                        --log("New expanded state: " .. tostring(originalItem.expanded), "PHASE2")
                                        --log("=== TOGGLE COMPLETE ===", "PHASE2")
                                        
                                        -- PHASE 3: Identify child items
                                        --log("=== IDENTIFYING CHILDREN ===", "PHASE3")
                                        --log("Looking for children of tier " .. self.itemData.tier .. " (next tier: " .. (self.itemData.tier + 1) .. ")", "PHASE3")
                                        
                                        local childrenFound = 0
                                        for j = i + 1, #recipeData do
                                            local potentialChild = recipeData[j]
                                            
                                            -- Stop searching if we hit an item at same or lower tier (not a descendant)
                                            if potentialChild.tier <= self.itemData.tier then
                                                --log("Stopped search at tier " .. potentialChild.tier .. " item: " .. potentialChild.name, "PHASE3")
                                                break
                                            end
                                            
                                            -- This is a descendant (higher tier number)
                                            --log("Found descendant - Tier " .. potentialChild.tier .. ": " .. potentialChild.name, "PHASE3")
                                            childrenFound = childrenFound + 1
                                        end
                                        
                                        --log("Total descendants found: " .. childrenFound, "PHASE3")
                                        --log("=== CHILDREN IDENTIFICATION COMPLETE ===", "PHASE3")
                                        
                                        -- PHASE 4: Filter recipeData to show only visible items
                                        --log("=== FILTERING VISIBLE ITEMS ===", "PHASE4")
                                        local visibleData = {}
                                        
                                        for k, item in ipairs(recipeData) do
                                            local shouldShow = true
                                            
                                            if item.tier == 0 then
                                                -- Always show main item (tier 0)
                                                shouldShow = true
                                                --log("Tier 0 - Always show: " .. item.name, "PHASE4")
                                            else
                                                -- For child items, check if any ancestor in the lineage is collapsed
                                                shouldShow = true
                                                
                                                -- Build the ancestry chain by walking backwards through tiers
                                                for checkTier = item.tier - 1, 0, -1 do
                                                    local ancestorAtTier = nil
                                                    
                                                    -- Find the most recent item at this tier level
                                                    for parentIndex = k - 1, 1, -1 do
                                                        local potentialAncestor = recipeData[parentIndex]
                                                        if potentialAncestor.tier == checkTier then
                                                            ancestorAtTier = potentialAncestor
                                                            break
                                                        end
                                                    end
                                                    
                                                    -- If we found an ancestor at this tier and it's collapsed, hide this item
                                                    if ancestorAtTier and not ancestorAtTier.expanded then
                                                        shouldShow = false
                                                        --log("Hidden by collapsed ancestor: " .. item.name .. " (ancestor: " .. ancestorAtTier.name .. " at tier " .. checkTier .. ")", "PHASE4")
                                                        break
                                                    end
                                                end
                                                
                                                if shouldShow then
                                                    --log("Tier " .. item.tier .. " - Show: " .. item.name, "PHASE4")
                                                end
                                            end
                                            
                                            if shouldShow then
                                                table.insert(visibleData, item)
                                            end
                                        end
                                        
                                        --log("Total visible items: " .. #visibleData .. " out of " .. #recipeData, "PHASE4")
                                        --log("=== FILTERING COMPLETE ===", "PHASE4")
                                        
                                        -- PHASE 5: Update scroll list with filtered visible data
                                        --log("=== UPDATING SCROLL LIST ===", "PHASE5")
                                        --log("Updating scroll list with " .. #visibleData .. " items", "PHASE5")
                                        
                                        if recipeWindow and recipeWindow.itemList then
                                            recipeWindow.itemList:UpdateData(visibleData)
                                            --log("Scroll list updated successfully", "PHASE5")
                                        else
                                            --log("ERROR: recipeWindow or itemList not found", "PHASE5")
                                        end
                                        
                                        --log("=== SCROLL LIST UPDATE COMPLETE ===", "PHASE5")
                                        break
                                    end
                                end
                            
                            elseif mouseButton == "RightButton" then
                                -- BUY/CRAFT Phase 1: Right-click detection and logging
                                --log("=== RIGHT-CLICK DETECTED ===", "BUY_CRAFT_PHASE1")
                                --log("Item: " .. tostring(self.itemData.name), "BUY_CRAFT_PHASE1")
                                --log("Current buy status: " .. tostring(self.itemData.buy), "BUY_CRAFT_PHASE1")
                                --log("Tier: " .. tostring(self.itemData.tier), "BUY_CRAFT_PHASE1")
                                --log("ID: " .. tostring(self.itemData.id), "BUY_CRAFT_PHASE1")
                                --log("=== RIGHT-CLICK LOG COMPLETE ===", "BUY_CRAFT_PHASE1")
                                
                                -- BUY/CRAFT Phase 2: Toggle buy status in recipeData
                                --log("=== SEARCHING FOR ITEM IN RECIPEDATA ===", "BUY_CRAFT_PHASE2")
                                for i, originalItem in ipairs(recipeData) do
                                    if originalItem.id == self.itemData.id and originalItem.tier == self.itemData.tier then
                                        log("Found original item at index " .. i, "BUY_CRAFT_PHASE2")
                                        log("Original buy status: " .. tostring(originalItem.buy), "BUY_CRAFT_PHASE2")
                                        
                                        -- Toggle the buy status
                                        originalItem.buy = not originalItem.buy
                                        
                                        -- Also update the stored itemData for consistency
                                        self.itemData.buy = originalItem.buy
                                        
                                        -- Adjust labor cost based on buy/craft decision
                                        if originalItem.buy then
                                            -- If buying, set labor cost to 0 (not crafting it)
                                            originalItem.displayLaborCost = 0
                                            self.itemData.laborCost = 0
                                            log("Item marked as BUY - labor cost set to 0", "BUY_CRAFT_PHASE2")
                                        else
                                            -- If crafting, restore original labor cost
                                            originalItem.displayLaborCost = originalItem.laborCost or 0
                                            self.itemData.laborCost = originalItem.laborCost or 0
                                            log("Item marked as CRAFT - labor cost restored to " .. (originalItem.laborCost or 0), "BUY_CRAFT_PHASE2")
                                        end
                                        
                                        log("New buy status: " .. tostring(originalItem.buy), "BUY_CRAFT_PHASE2")
                                        log("Updated itemData buy status: " .. tostring(self.itemData.buy), "BUY_CRAFT_PHASE2")
                                        log("Updated labor cost: " .. (originalItem.displayLaborCost or 0), "BUY_CRAFT_PHASE2")
                                        log("=== BUY STATUS TOGGLE COMPLETE ===", "BUY_CRAFT_PHASE2")
                                        
                                        -- CASCADE Phase 1: Handle visual collapse when parent is marked as buy
                                        if originalItem.buy then
                                            log("=== VISUAL COLLAPSE - PARENT MARKED AS BUY ===", "CASCADE_PHASE1")
                                            log("Parent item " .. originalItem.name .. " marked as BUY - collapsing for display only", "CASCADE_PHASE1")
                                            
                                            -- Collapse the parent item visually since its children are less relevant for display
                                            originalItem.expanded = false
                                            log("Collapsed parent item: " .. originalItem.name .. " (children keep their buy states)", "CASCADE_PHASE1")
                                            
                                            log("=== VISUAL COLLAPSE COMPLETE ===", "CASCADE_PHASE1")
                                        else
                                            log("=== VISUAL EXPAND - PARENT MARKED AS CRAFT ===", "CASCADE_PHASE1") 
                                            log("Parent item " .. originalItem.name .. " marked as CRAFT - expanding tree", "CASCADE_PHASE1")
                                            
                                            -- When switching to craft, expand the item to show its recipe components
                                            originalItem.expanded = true
                                            log("Expanded parent item: " .. originalItem.name, "CASCADE_PHASE1")
                                            log("=== VISUAL EXPAND COMPLETE ===", "CASCADE_PHASE1")
                                        end
                                        
                                        -- LABOR RECALC Phase: Recalculate total labor for tier 0 item
                                        --log("=== RECALCULATING TOTAL LABOR ===", "LABOR_RECALC")
                                        --log("Total items in recipe: " .. #recipeData, "LABOR_RECALC")
                                        local totalLabor = 0
                                        
                                        -- Sum up all labor costs, excluding items marked as "buy" and ALL their children
                                        for k, item in ipairs(recipeData) do
                                            local shouldSkip = false
                                            local skipReason = ""
                                            
                                            if item.buy then
                                                shouldSkip = true
                                                skipReason = "marked as buy"
                                            else
                                                -- Check if this item is a child of ANY item marked as "buy"
                                                -- Look backwards through the array to find potential parents
                                                for parentIndex = k - 1, 1, -1 do
                                                    local potentialParent = recipeData[parentIndex]
                                                    
                                                    -- If we find an item at a lower tier (higher in hierarchy) that's marked as buy
                                                    if potentialParent.tier < item.tier and potentialParent.buy then
                                                        -- Check if this potential parent is actually a parent by checking tier progression
                                                        local isValidParent = true
                                                        
                                                        -- Verify there's a valid tier progression path (no gaps in tiers)
                                                        for checkIndex = parentIndex + 1, k - 1 do
                                                            local intermediateItem = recipeData[checkIndex]
                                                            -- If there's an item at the same tier as potential parent between them, it's not a valid parent
                                                            if intermediateItem.tier <= potentialParent.tier then
                                                                isValidParent = false
                                                                break
                                                            end
                                                        end
                                                        
                                                        if isValidParent then
                                                            shouldSkip = true
                                                            skipReason = "child of " .. potentialParent.name .. " (marked as buy)"
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            if not shouldSkip then
                                                -- PHASE 3.6: Use existing labor cost data (no API calls!)
                                                local itemLabor = 0
                                                local baseLabor = item.laborCost or 0
                                                local amount = item.amount or 1
                                                itemLabor = baseLabor * amount
                                                totalLabor = totalLabor + itemLabor
                                                --log("PHASE3.6: Using existing labor data for " .. item.name .. " - labor=" .. itemLabor .. " (no API calls!)", "PHASE3_FINAL")
                                                --log("Counting - " .. item.name .. " (tier " .. item.tier .. ", buy=" .. tostring(item.buy) .. ") - labor=" .. itemLabor, "LABOR_RECALC")
                                            else
                                                --log("Skipping - " .. item.name .. " (tier " .. item.tier .. ", buy=" .. tostring(item.buy) .. ") - " .. skipReason, "LABOR_RECALC")
                                            end
                                        end
                                        
                                        -- Update the main item (tier 0) with the new total labor
                                        for k, item in ipairs(recipeData) do
                                            if item.tier == 0 then
                                                item.totalLaborCost = totalLabor
                                                --log("Updated tier 0 total labor cost to: " .. totalLabor, "LABOR_RECALC")
                                                
                                                -- Update the total labor value label
                                                if totalLaborVauleLabel then
                                                    totalLaborVauleLabel:SetText(tostring(totalLabor))
                                                end
                                                
                                                break
                                            end
                                        end
                                        
                                        --log("=== LABOR RECALCULATION COMPLETE ===", "LABOR_RECALC")
                                        
                                        -- COST RECALC Phase: Recalculate total cost for tier 0 item
                                        log("=== RECALCULATING TOTAL COST ===", "COST_RECALC")
                                        local totalCost = 0
                                        
                                        -- Sum up all material costs from items marked as "buy" (opposite of labor logic)
                                        for k, item in ipairs(recipeData) do
                                            local shouldCountCost = true
                                            
                                            -- Check if this item should be counted (skip if parent is marked as "buy")
                                            if item.tier > 0 then
                                                for checkTier = item.tier - 1, 0, -1 do
                                                    local ancestorAtTier = nil
                                                    
                                                    for parentIndex = k - 1, 1, -1 do
                                                        local potentialAncestor = recipeData[parentIndex]
                                                        if potentialAncestor.tier == checkTier then
                                                            ancestorAtTier = potentialAncestor
                                                            break
                                                        end
                                                    end
                                                    
                                                    if ancestorAtTier and ancestorAtTier.buy then
                                                        shouldCountCost = false
                                                        break
                                                    end
                                                end
                                            end
                                            
                                            if shouldCountCost then
                                                local itemCost = 0
                                                if item.buy then
                                                    -- If buying, use market price
                                                    local marketPrice = marketdata[item.id] and marketdata[item.id].average or 0
                                                    local amount = item.amount or 1
                                                    itemCost = marketPrice * amount
                                                    log("COST RECALC: Adding cost for " .. item.name .. " - cost=" .. itemCost .. " (price=" .. marketPrice .. ", amount=" .. amount .. ")", "COST_RECALC")
                                                end
                                                totalCost = totalCost + itemCost
                                                --log("Item " .. item.name .. " (tier " .. item.tier .. ") - cost=" .. itemCost, "COST_RECALC")
                                            end
                                        end
                                        
                                        -- Update the main item (tier 0) with the new total cost
                                        for k, item in ipairs(recipeData) do
                                            if item.tier == 0 then
                                                item.totalMaterialCost = totalCost
                                                log("Updated tier 0 total material cost to: " .. totalCost, "COST_RECALC")
                                                
                                                -- Update the total cost value label
                                                if totalCostValueLabel then
                                                    totalCostValueLabel:SetText(tostring(totalCost))
                                                    log("Updated total cost label to: " .. totalCost, "COST_RECALC")
                                                end
                                                
                                                break
                                            end
                                        end
                                        
                                        log("=== COST RECALCULATION COMPLETE ===", "COST_RECALC")
                                        
                                        -- BUY/CRAFT Phase 3: Filter visible items and update display
                                        log("=== FILTERING VISIBLE ITEMS AFTER CASCADE ===", "BUY_CRAFT_PHASE3")
                                        local visibleData = {}
                                        
                                        for k, item in ipairs(recipeData) do
                                            local shouldShow = true
                                            
                                            if item.tier == 0 then
                                                -- Always show main item (tier 0)
                                                shouldShow = true
                                                log("Tier 0 - Always show: " .. item.name, "BUY_CRAFT_PHASE3")
                                            else
                                                -- For child items, check if any ancestor in the lineage is collapsed
                                                shouldShow = true
                                                
                                                -- Build the ancestry chain by walking backwards through tiers
                                                for checkTier = item.tier - 1, 0, -1 do
                                                    local ancestorAtTier = nil
                                                    
                                                    -- Find the most recent item at this tier level
                                                    for parentIndex = k - 1, 1, -1 do
                                                        local potentialAncestor = recipeData[parentIndex]
                                                        if potentialAncestor.tier == checkTier then
                                                            ancestorAtTier = potentialAncestor
                                                            break
                                                        end
                                                    end
                                                    
                                                    -- If we found an ancestor at this tier and it's collapsed, hide this item
                                                    if ancestorAtTier and not ancestorAtTier.expanded then
                                                        shouldShow = false
                                                        log("Hidden by collapsed ancestor: " .. item.name .. " (ancestor: " .. ancestorAtTier.name .. " at tier " .. checkTier .. ")", "BUY_CRAFT_PHASE3")
                                                        break
                                                    end
                                                end
                                                
                                                if shouldShow then
                                                    log("Tier " .. item.tier .. " - Show: " .. item.name, "BUY_CRAFT_PHASE3")
                                                end
                                            end
                                            
                                            if shouldShow then
                                                table.insert(visibleData, item)
                                            end
                                        end
                                        
                                        log("Total visible items: " .. #visibleData .. " out of " .. #recipeData, "BUY_CRAFT_PHASE3")
                                        
                                        -- BUY/CRAFT Phase 4: Update display with filtered visible data
                                        log("=== UPDATING DISPLAY AFTER CASCADE ===", "BUY_CRAFT_PHASE4")
                                        if recipeWindow and recipeWindow.itemList then
                                            log("Refreshing scroll list with " .. #visibleData .. " visible items", "BUY_CRAFT_PHASE4")
                                            recipeWindow.itemList:UpdateData(visibleData)
                                            log("Display update complete", "BUY_CRAFT_PHASE4")
                                        else
                                            log("ERROR: recipeWindow or itemList not found", "BUY_CRAFT_PHASE4")
                                        end
                                        log("=== DISPLAY UPDATE COMPLETE ===", "BUY_CRAFT_PHASE4")
                                        
                                        break
                                    end
                                end
                            end
                        end
                        subItem:SetHandler("OnMouseUp", subItem.OnClick)
                    end
                end
            },
            {
                name = "Amount",
                width = 80,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(tostring(rowData.amount))
                    end
                end
            },
            {
                name = "Labor Cost",
                width = 100,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        if rowData.tier == 0 then
                            -- PHASE 3.6: For tier 0, show individual craft cost (stored should be base, not total)
                            local baseLabor = rowData.laborCost or 0
                            local individualLabor = rowData.buy and 0 or baseLabor
                            --log("Tier 0 labor display: " .. rowData.name .. " - base=" .. baseLabor .. " (using stored base)", "LABOR_FIX")
                            if rowData.buy then
                                subItem:SetText("0 (BUY)")
                                ApplyTextColor(subItem, FONT_COLOR.GREEN)
                            else
                                subItem:SetText(tostring(individualLabor))
                                ApplyTextColor(subItem, FONT_COLOR.DEFAULT)  -- Normal color, not red
                            end
                        else
                            -- For other items, show total labor cost (base * amount)
                            local baseLabor = rowData.laborCost or 0
                            local amount = rowData.amount or 1
                            local totalItemLabor = rowData.buy and 0 or (baseLabor * amount)
                            
                            if totalItemLabor > 0 then
                                subItem:SetText(tostring(totalItemLabor))
                                ApplyTextColor(subItem, FONT_COLOR.DEFAULT)
                            else
                                subItem:SetText(rowData.buy and "0 (BUY)" or "")  -- Show why it's 0
                                ApplyTextColor(subItem, rowData.buy and FONT_COLOR.GREEN or FONT_COLOR.DEFAULT)
                            end
                        end
                    end
                end
            },
        }
        
        totalLaborLabel = gui.AddLabel(
            recipeWindow,                     -- parent window
            "totalLaborLabel",                   -- unique ID
            "Total Labor: ",  -- initial text
            "TOPLEFT",                         -- anchor to left of search box
            recipeWindow,                      -- anchor target
            20,                            -- x offset (right of 300px search box + 10px gap)
            20,                              -- y offset (same level as search box)
            FONT_SIZE.LARGE,               -- font size
            3,                             -- align type
            {1, 1, 1, 1},                  -- font color (white)
            10                             -- minimal padding
        )

        totalLaborVauleLabel = gui.AddLabel(
            recipeWindow,                     -- parent window
            "totalLaborLabel",                   -- unique ID
            tostring(initialTotalLabor),  -- initial text set to calculated total
            "LEFT",                         -- anchor to left of search box
            totalLaborLabel,                      -- anchor target
            80,                            -- x offset (right of 300px search box + 10px gap)
            0,                              -- y offset (same level as search box)
            FONT_SIZE.LARGE,               -- font size
            3,                             -- align type
            {1, 1, 0, 1},                  -- font color (yellow)
            10                             -- minimal padding
        )

        totalCostLabel = gui.AddLabel(
            recipeWindow,                     -- parent window
            "totalLaborLabel",                   -- unique ID
            "Total Cost: ",  -- initial text
            "TOPLEFT",                         -- anchor to left of search box
            recipeWindow,                      -- anchor target
            20,                            -- x offset (right of 300px search box + 10px gap)
            50,                              -- y offset (same level as search box)
            FONT_SIZE.LARGE,               -- font size
            3,                             -- align type
            {1, 1, 1, 1},                  -- font color (white)
            10                             -- minimal padding
        )

        totalCostValueLabel = gui.AddLabel(
            recipeWindow,                     -- parent window
            "totalLaborLabel",                   -- unique ID
            tostring(initialTotalCost),  -- initial text set to calculated total
            "LEFT",                         -- anchor to left of search box
            totalCostLabel,                      -- anchor target
            80,                            -- x offset (right of 300px search box + 10px gap)
            0,                              -- y offset (same level as search box)
            FONT_SIZE.LARGE,               -- font size
            3,                             -- align type
            {1, 1, 0, 1},                  -- font color (yellow)
            10                             -- minimal padding
        )


        -- Create the scroll list
        --log("About to create scroll list with " .. #recipeData .. " items", "RECIPE_DISPLAY")
        
        -- Create the scroll list (simple version)
        recipeWindow.itemList = gui.AddScrollList(
            recipeWindow, "recipeList", columns,
            { point = "TOPLEFT", relativeTo = recipeWindow, offsetX = 20, offsetY = 70 },
            { width = 760, height = 400 },
            {
                listType = 3,
                rowCount = 20,
                columnHeight = 35,
                enableColumns = true,
                dataSource = recipeData,

            }
        )
        
        -- Update the list with our data
        if recipeWindow.itemList then
            recipeWindow.itemList:UpdateData(recipeData)
            log("Scroll list created and data updated successfully", "RECIPE_DISPLAY")
        else
            log("ERROR: Failed to create scroll list", "RECIPE_DISPLAY")
        end
        
        log("Created recipe window with " .. #recipeData .. " items", "RECIPE_DISPLAY")
    end

    -- Helper function to count table entries
    local function GetTableCount(tbl)
        local count = 0
        for _ in pairs(tbl) do count = count + 1 end
        return count
    end
    
    -- Compact table serializer - everything on one line
    local function SerializeTable(tbl, depth)
        depth = depth or 0
        if depth > 10 then return "{}" end -- Prevent infinite recursion
        
        local parts = {}
        local isArray = #tbl > 0
        
        for k, v in pairs(tbl) do
            local key = isArray and "" or (type(k) == "string" and k or ("[" .. tostring(k) .. "]")) .. " = "
            local value
            
            if type(v) == "table" then
                value = SerializeTable(v, depth + 1)
            elseif type(v) == "string" then
                value = "\"" .. v .. "\""
            elseif type(v) == "boolean" then
                value = tostring(v)
            else
                value = tostring(v or 0)
            end
            
            table.insert(parts, key .. value)
        end
        
        return "{" .. table.concat(parts, ",") .. "}"
    end
    

    -- Process saved item data for UI display (calculate missing fields)
    local function ProcessSavedItemsForUI()
        -- "ProcessSavedItemsForUI called", "DEBUG")
        
        local savedItems = api.File:Read(config.files.itemList) or {}
        -- "File read returned " .. #savedItems .. " items", "DEBUG")
        
        local processedItems = {}
        
        for i, item in ipairs(savedItems) do
            -- "Processing item " .. i .. ": " .. (item.name or "Unknown") .. " (ID: " .. (item.id or "N/A") .. ")", "DEBUG")
            
            -- Calculate costs from cached data
            local cost, value, profit = ReadMarketData(item, marketdata)
            
            -- Build UI-ready item data
            local processedItem = {
                id = item.id,
                name = item.name,
                cost = cost,
                value = value,
                profit = profit,
                laborCost = item.laborCost or 0,
                workbench = item.workbench or "Default",
                materials = item.materials,  -- Recipe-specific materials with buy/craft preferences
                dependencies = item.dependencies  -- Complete dependency tree
            }
            
            -- Calculate Silver per Labor if we have both values
            if processedItem.profit and processedItem.laborCost and processedItem.laborCost > 0 then
                processedItem.silverPerLabor = processedItem.profit / processedItem.laborCost
            else
                processedItem.silverPerLabor = 0
            end
            
            table.insert(processedItems, processedItem)
        end
        
        -- "ProcessSavedItemsForUI returning " .. #processedItems .. " processed items", "DEBUG")
        return processedItems
    end

   



    -- Calculate costs directly from dependency tree data (no API calls)
    local function CalculateFromDependencyTree(dependencyTree, rootItemId)
        -- log("CalculateFromDependencyTree called for item " .. rootItemId, "CALC_DEBUG")
        
        local function calculateRecursive(itemId, quantity, visited)
            visited = visited or {}
            quantity = quantity or 1
            
            -- Prevent infinite recursion
            if visited[itemId] then return 0, 0 end
            visited[itemId] = true
            
            -- Get item data from dependency tree
            local itemData = dependencyTree[itemId]
            if not itemData then
                -- log("WARNING: Item " .. itemId .. " not found in dependency tree", "CALC_DEBUG")
                visited[itemId] = nil
                return 0, 0
            end
            -- log("Processing item " .. itemData.name .. " (ID: " .. itemId .. ")", "CALC_DEBUG")
            
            -- Get market price (fallback to 0 if not available)
            local marketPrice = marketdata[itemId] and marketdata[itemId].average or 0
            -- log("Market price for " .. itemData.name .. ": " .. marketPrice, "CALC_DEBUG")
            
            -- Check materials safely
            -- log("Checking materials for " .. itemData.name .. ", materials type: " .. type(itemData.materials or "nil"), "CALC_DEBUG")
            
            local hasMaterials = false
            if itemData.materials and type(itemData.materials) == "table" then
                for _ in pairs(itemData.materials) do
                    hasMaterials = true
                    break
                end
            end
            
            -- If item has no materials (raw material), use market price with no labor
            if not hasMaterials then
                -- log("Item " .. itemData.name .. " is raw material, using market price", "CALC_DEBUG")
                visited[itemId] = nil
                return 0, marketPrice * quantity
            end
            
            -- log("Item " .. itemData.name .. " has materials, calculating craft costs", "CALC_DEBUG")
            
            -- Calculate crafting costs
            local itemLabor = (itemData.laborCost or 0) * quantity
            local totalChildLabor = 0
            local totalMaterialCost = 0
            
            -- Process all materials
            for stringKey, matInfo in pairs(itemData.materials) do
                local matId = matInfo.id
                local matQuantity = matInfo.amount * quantity
                local shouldBuy = matInfo.buy
                
                if shouldBuy then
                    -- Buy this material - use market price, no labor
                    local matMarketPrice = marketdata[matId] and marketdata[matId].average or 0
                    totalMaterialCost = totalMaterialCost + (matMarketPrice * matQuantity)
                else
                    -- Craft this material - recurse
                    local childLabor, childCost = calculateRecursive(matId, matQuantity, visited)
                    totalChildLabor = totalChildLabor + childLabor
                    totalMaterialCost = totalMaterialCost + childCost
                end
            end
            
            local totalLabor = itemLabor + totalChildLabor
            visited[itemId] = nil
            return totalLabor, totalMaterialCost
        end
        
        -- Calculate for the root item
        local totalLabor, totalCost = calculateRecursive(rootItemId, 1, {})
        local marketValue = marketdata[rootItemId] and marketdata[rootItemId].average or 0
        local profit = marketValue - totalCost
        
        return {
            laborCost = totalLabor,
            cost = totalCost,
            value = marketValue,
            profit = profit
        }
    end

    -- Recursively collect all child recipe data to store complete dependency tree
    local function CollectDependencyTree(rootItemId, processedDeps, level)
        processedDeps = processedDeps or {}
        level = level or 0
        
        -- "Processing item " .. rootItemId .. " at level " .. level, "TREE")
        
        if level > 10 then 
            -- "Hit recursion limit for item " .. rootItemId, "TREE")
            return processedDeps 
        end
        if processedDeps[rootItemId] then 
            -- "Item " .. rootItemId .. " already processed", "TREE")
            return processedDeps 
        end
        
        -- Get item data from API
        local itemInfo = api.Item:GetItemInfoByType(rootItemId)
        if not itemInfo then 
            -- "No item info found for " .. rootItemId, "TREE")
            return processedDeps 
        end
        
        -- "Found item: " .. itemInfo.name, "TREE")
        
        local craftType = api.Craft:GetCraftTypeByItemType(rootItemId)
        local craftBaseInfo = craftType and api.Craft:GetCraftBaseInfo(craftType)
        local materialsInfo = craftType and api.Craft:GetCraftMaterialInfo(craftType)
        
        -- Mass production detection using baseInfo.title containing "Mass Production"
        local isMassProduction = false
        local massProductionRatio = 1
        if craftBaseInfo and craftBaseInfo.title then
            if string.find(craftBaseInfo.title, "Mass Production") then
                isMassProduction = true
                massProductionRatio = 10  -- All mass production recipes use 10:1 ratio
                log("Mass production detected for " .. itemInfo.name .. ": " .. craftBaseInfo.title, "MASS_PROD")
            end
        end
        
        
        if not craftType then
            -- "Item " .. itemInfo.name .. " is not craftable (no craft type)", "TREE")
        else
            -- "Item " .. itemInfo.name .. " has craft type, checking materials...", "TREE")
        end
        
        -- Store recipe data for ALL items (craftable and raw materials)
        if craftType and materialsInfo then
            -- "Item " .. itemInfo.name .. " has " .. (#materialsInfo or 0) .. " materials", "TREE")
            
            local materials = {}
            local childIds = {}
            
            for i, matData in pairs(materialsInfo) do
                if matData.item_info and matData.item_info.itemType ~= 500 then
                    local matId = matData.item_info.itemType
                    local matName = matData.item_info.name
                    
                    -- Apply mass production adjustment to material amounts
                    local adjustedAmount = matData.amount
                    if isMassProduction then
                        adjustedAmount = matData.amount / massProductionRatio
                        log("Adjusted " .. matName .. " amount: " .. matData.amount .. " -> " .. adjustedAmount .. " (÷" .. massProductionRatio .. ")", "MASS_PROD")
                    end
                    
                    -- "Material " .. i .. ": " .. matName .. " (ID: " .. matId .. ", amount: " .. adjustedAmount .. ")", "TREE")
                    
                    local stringKey = "id_" .. string.format("%.0f", matId)
                    materials[stringKey] = {
                        id = tonumber(string.format("%.0f", matId)),
                        name = matName,
                        amount = adjustedAmount,
                        buy = false  -- Default to craft
                    }
                    table.insert(childIds, matId)
                else
                    if matData.item_info then
                        -- "Skipping material (coin): " .. matData.item_info.name .. " (ID: " .. matData.item_info.itemType .. ")", "TREE")
                    else
                        -- "Skipping material (no item_info)", "TREE")
                    end
                end
            end
            
            -- "Found " .. #childIds .. " child materials to process", "TREE")
            
            -- Adjust labor cost for mass production
            local adjustedLaborCost = craftBaseInfo and craftBaseInfo.consume_lp or 0
            if isMassProduction then
                adjustedLaborCost = adjustedLaborCost / massProductionRatio
                log("Adjusted " .. itemInfo.name .. " labor cost: " .. (craftBaseInfo.consume_lp or 0) .. " -> " .. adjustedLaborCost .. " (÷" .. massProductionRatio .. ")", "MASS_PROD")
            end
            
            -- Store recipe data for craftable items
            processedDeps[rootItemId] = {
                id = tonumber(string.format("%.0f", rootItemId)),
                name = itemInfo.name,
                laborCost = adjustedLaborCost,
                workbench = (craftBaseInfo and craftBaseInfo.doodad_name) and craftBaseInfo.doodad_name or "Default",
                materials = materials
            }
            
            -- Recursively process all child materials (both craftable and raw)
            for _, childId in ipairs(childIds) do
                if not config.excludedItems[childId] then  -- Skip excluded items
                    -- "Recursively processing child: " .. childId, "TREE")
                    CollectDependencyTree(childId, processedDeps, level + 1)
                else
                    -- "Skipping excluded item: " .. childId, "TREE")
                end
            end
        else
            -- Store raw material data (even if not craftable)
            -- "Item " .. itemInfo.name .. " is raw material, storing basic info", "TREE")
            processedDeps[rootItemId] = {
                id = tonumber(string.format("%.0f", rootItemId)),
                name = itemInfo.name,
                laborCost = 0,  -- Raw materials have no labor cost
                workbench = "Raw Material",  -- Raw materials don't need workbenches
                materials = {}  -- Raw materials have no sub-materials
            }
        end
        
        return processedDeps
    end


-- Utility: compact table serializer
local function serializeCompact(tbl)
    local parts = {}
    for k, v in pairs(tbl) do
        local key = type(k) == "string" and k or ("["..k.."]")
        local value
        if type(v) == "table" then
            value = "{" .. serializeCompact(v) .. "}"
        elseif type(v) == "string" then
            value = string.format("%q", v)
        else
            value = tostring(v)
        end
        table.insert(parts, key .. "=" .. value)
    end
    return table.concat(parts, ",")
end



    -- Add a new item to item_list.lua so it gets processed on load next time
    local function AddItemToList(itemId)
        -- log("AddItemToList called for item " .. itemId, "ADD_ITEM_DEBUG")
        
        -- Use cached item list if available, otherwise try to read from file
        local existingData
        if cachedItemList then
            existingData = cachedItemList
        else
            existingData = api.File:Read(config.files.itemList) or {}
            cachedItemList = existingData  -- Cache it for future use
        end
        
        -- Use existing data directly (back to original format)
        local existingItems = existingData
        
        -- Check if item already exists
        for _, existingItem in ipairs(existingItems) do
            if existingItem.id == itemId then
                -- "Item " .. itemId .. " already exists in list", "DEBUG")
                return false
            end
        end
        
        -- Collect complete dependency tree for this item and all children
        local dependencyTree = CollectDependencyTree(itemId)
        -- log("CollectDependencyTree completed, found " .. (dependencyTree and table_count(dependencyTree) or 0) .. " dependencies", "ADD_ITEM_DEBUG")
        
        -- Get main item data
        local mainItemData = dependencyTree[itemId]
        if not mainItemData then
            -- log("ERROR: Could not find main item data for " .. itemId .. " in dependency tree", "ADD_ITEM_DEBUG")
            return false
        end
        
        
        -- Calculate costs directly from dependency tree (no API calls)
        local calculatedData = CalculateFromDependencyTree(dependencyTree, itemId)
        
        -- Debug: Check if calculation worked
        if not calculatedData then
            -- log("ERROR: CalculateFromDependencyTree returned nil for item " .. itemId, "ADD_ITEM_DEBUG")
            return false
        end
        -- log("Calculated costs for " .. mainItemData.name .. ": cost=" .. (calculatedData.cost or 0) .. ", labor=" .. (calculatedData.laborCost or 0), "ADD_ITEM_DEBUG")
        
        -- Build complete item record with recipe-specific buy/craft preferences
        local fileFriendlyItem = {
            -- Basic item info
            laborCost = mainItemData.laborCost or 0,  -- Store base craft cost, not total recipe cost
            name = mainItemData.name,
            cost = calculatedData and calculatedData.cost or 0,
            id = tonumber(string.format("%.0f", itemId)),
            value = calculatedData and calculatedData.value or 0,
            profit = calculatedData and calculatedData.profit or 0,
            workbench = mainItemData.workbench or "Default",
            
            -- Direct materials for this recipe with individual buy/craft decisions
            materials = mainItemData.materials or {},
            
            -- Complete dependency tree - all child recipes stored here  
            dependencies = {}
        }
        
        -- Add all dependency recipes (excluding the main item itself)
        for depId, depData in pairs(dependencyTree) do
            if depId ~= itemId then  -- Don't duplicate the main item
                local stringKey = "id_" .. string.format("%.0f", depId)  -- Convert numeric ID to string key
                fileFriendlyItem.dependencies[stringKey] = depData
            end
        end
        
        -- Add to existing items
        table.insert(existingItems, fileFriendlyItem)
        -- "Now have " .. #existingItems .. " items total, saving to file", "DEBUG")
        
        -- Update the cache
        cachedItemList = existingItems
        
        -- Save back to file
        api.File:Write(config.files.itemList, existingItems)
        --local serialized = "return {" .. serializeCompact(existingItems) .. "}"
        --api.File:Write(config.files.itemList, serialized)
        -- "Saved " .. #existingItems .. " items to file", "DEBUG")
        
        -- Clear the cache so UI refresh will re-read from file
        cachedItemList = nil
        -- "Cleared cachedItemList cache", "DEBUG")
        
        -- "Successfully added " .. mainItemData.name .. " (ID: " .. itemId .. ") to item list", "DEBUG")
        

        return true
    end
  
    -- Create the main data grid with clean column layout on the main window!
    local function CreateMainDataGrid(itemData, listanchorPoint, listanchorTarget, listoffsetx, listoffsety)
        -- "Creating main data grid with " .. #itemData .. " items", "UI_CREATION")
        
        local columns = {
            {
                name = "ID",
                width = 80,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(string.format("%.0f", rowData.id))
                    end
                end
            },
            {
                name = "Name", 
                width = 180,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(rowData.name)
                    end
                end
            },
            {
                name = "Cost",
                width = 100,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(format4(rowData.cost or 0))
                    end
                end
            },
            {
                name = "Value",
                width = 100,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(format4(rowData.value or 0))
                    end
                end
            },
            {
                name = "Profit",
                width = 100,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(format4(rowData.profit or 0))
                    end
                end
            },
            {
                name = "Labor",
                width = 80,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(tostring(rowData.laborCost or 0))
                    end
                end
            },
            {
                name = "Workbench",
                width = 160,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(rowData.workbench or "Default")
                    end
                end
            },
            {
                name = "Silver/Labor",
                width = 120,
                setFunc = function(subItem, rowData, setValue)
                    if setValue then
                        subItem:SetText(format4(rowData.silverPerLabor or 0))
                    end
                end
            },
            {
                name = "Actions", 
                width = 120,
                setFunc = function(subItem, rowData, setValue)
                    if setValue == false then
                        -- Hide buttons when row is empty
                        if subItem.edit then subItem.edit:Show(false) end
                        if subItem.moveUp then subItem.moveUp:Show(false) end
                        if subItem.moveDown then subItem.moveDown:Show(false) end
                        return
                    end
                    
                    -- Show buttons when row has data
                    if subItem.edit then 
                        subItem.edit:Show(true)
                        subItem.edit:Enable(true)
                    end
                    if subItem.moveUp then
                        subItem.moveUp:Enable(subItem.moveUp.rowIndex ~= 1)
                        subItem.moveUp:Show(true)
                    end
                    if subItem.moveDown then
                        -- Get the current data count from the list  
                        local dataCount = mainWindow.itemList and #mainWindow.itemList.dataSource or 0
                        subItem.moveDown:Enable(subItem.moveDown.rowIndex ~= dataCount)
                        subItem.moveDown:Show(true)
                    end
                end,
                layoutFunc = function(itemList, rowIndex, colIndex, subItem)
                    -- Edit button
                    local editButton = mainWindow:CreateChildWidget("button", subItem:GetId() .. ".edit", 0, true)
                    editButton:AddAnchor("LEFT", subItem, 2, 0)
                    editButton:SetExtent(25, 18)
                    subItem.edit = editButton
                    subItem.edit.rowIndex = rowIndex

                    function subItem.edit:OnClick(arg)
                        local data = itemList.dataSource[self.rowIndex]
                        if not data then return end
                        
                        log("Edit button clicked for row " .. data.id .. " - " .. data.name, "EDIT_BUTTON")
                        log("PHASE3.5: Passing item data to DisplayRecipeTree - no file read needed!", "PHASE3_FINAL")
                        -- Call DisplayRecipeTree function with item data (no API calls!)
                        DisplayRecipeTree(data.id, data)
                    end

                    subItem.edit:SetHandler("OnMouseUp", subItem.edit.OnClick)
                    api.Interface:ApplyButtonSkin(editButton, BUTTON_CONTENTS.APPELLATION or BUTTON_BASIC.DEFAULT)
                    subItem.edit:Show(false)
                    
                    -- Move Up button
                    local upButton = mainWindow:CreateChildWidget("button", subItem:GetId() .. ".up", 0, true)
                    upButton:AddAnchor("LEFT", editButton, "RIGHT", 2, 0)
                    upButton:SetExtent(25, 18)
                    subItem.moveUp = upButton
                    subItem.moveUp.name = ""
                    subItem.moveUp.rowIndex = rowIndex
                    
                    function subItem.moveUp:OnClick(arg)
                        if self.rowIndex > 1 then
                            local data = itemList.dataSource[self.rowIndex]
                            if data then
                                log("Moving up: " .. data.name .. " from row " .. self.rowIndex .. " to " .. (self.rowIndex - 1), "MOVE_BUTTONS")
                                itemList:SwapRows(self.rowIndex, self.rowIndex - 1)
                            end
                        end
                    end
                    subItem.moveUp:SetHandler("OnMouseUp", subItem.moveUp.OnClick)
                    api.Interface:ApplyButtonSkin(upButton, BUTTON_BASIC.PLUS)
                    subItem.moveUp:Show(false)
                    
                    -- Move Down button
                    local downButton = mainWindow:CreateChildWidget("button", subItem:GetId() .. ".down", 0, true)
                    downButton:AddAnchor("LEFT", upButton, "RIGHT", 2, 0)
                    downButton:SetExtent(25, 18)
                    subItem.moveDown = downButton
                    subItem.moveDown.name = ""
                    subItem.moveDown.rowIndex = rowIndex
                    
                    function subItem.moveDown:OnClick(arg)
                        local dataCount = itemList and #itemList.dataSource or 0
                        if self.rowIndex < dataCount then
                            local data = itemList.dataSource[self.rowIndex]
                            if data then
                                log("Moving down: " .. data.name .. " from row " .. self.rowIndex .. " to " .. (self.rowIndex + 1), "MOVE_BUTTONS")
                                itemList:SwapRows(self.rowIndex, self.rowIndex + 1)
                            end
                        end
                    end
                    subItem.moveDown:SetHandler("OnMouseUp", subItem.moveDown.OnClick)
                    api.Interface:ApplyButtonSkin(downButton, BUTTON_BASIC.MINUS)
                    subItem.moveDown:Show(false)
                end
            }
        }
        
        -- Create the scroll list and attach it to mainWindow
        -- "About to call gui.AddScrollList with " .. #columns .. " columns", "UI_CREATION")
        

        -- Create the scroll list (increased width to accommodate new columns)
        mainWindow.itemList = gui.AddScrollList(
            mainWindow,                          -- parent window
            "itemList",                          -- unique ID
            columns,                             -- column definitions (now includes button columns)
            {                                    -- anchor configuration
                point = listanchorPoint or "TOPLEFT", 
                relativeTo = listanchorTarget or mainWindow, 
                offsetX = listoffsetx or 0, 
                offsetY = listoffsety or 30
            },
            {                                    -- dimensions
                width = 1360,                    -- fixed width that fits in 1400px window
                height = 400                     -- fixed height
            },
            {                                    -- options
                listType = 3,                    -- default list type
                rowCount = 15,                   -- 15 rows
                columnHeight = 35,
                enableColumns = true,             -- columns clickable
                enablePagination = true
            }
        )

        -- "gui.AddScrollList completed successfully", "UI_CREATION")
        
        -- Update the list with our data
        mainWindow.itemList:UpdateData(itemData)
        
        -- "Successfully created and populated data grid", "UI_CREATION")
    end


        -- Print all item information in a detailed, formatted way
    local function PrintAllItemInfo()
        -- "=== PRINTING ALL ITEM INFORMATION ===", "PRINT_ITEMS")
        
        -- Read the item list from file
        local savedItems = api.File:Read(config.files.itemList)
        
        if not savedItems or #savedItems == 0 then
            -- "No items found in item list", "PRINT_ITEMS")
            api.Log:Info("No items to print")
            return
        end
        
        -- "Found " .. #savedItems .. " items to print", "PRINT_ITEMS")
        api.Log:Info("Printing " .. #savedItems .. " items...")
        
        -- Print each item with all details
        for i, item in ipairs(savedItems) do
            local separator = "================================"
            -- separator, "PRINT_ITEMS")
            -- "ITEM #" .. i .. ": " .. (item.name or "Unknown"), "PRINT_ITEMS")
            -- separator, "PRINT_ITEMS")
            
            -- Basic item information
            -- "ID: " .. (item.id or "N/A"), "PRINT_ITEMS")
            -- "Name: " .. (item.name or "Unknown"), "PRINT_ITEMS")
            -- "Cost: " .. format4(item.cost or 0) .. " silver", "PRINT_ITEMS")
            -- "Value: " .. format4(item.value or 0) .. " silver", "PRINT_ITEMS")
            -- "Profit: " .. format4(item.profit or 0) .. " silver", "PRINT_ITEMS")
            -- "Labor Cost: " .. (item.laborCost or 0) .. " LP", "PRINT_ITEMS")
            
            -- Calculate silver per labor if we have both values
            if item.profit and item.laborCost and item.laborCost > 0 then
                local silverPerLabor = item.profit / item.laborCost
                -- "Silver per Labor: " .. format4(silverPerLabor) .. " silver/LP", "PRINT_ITEMS")
            end
            
            -- Recipe information
            if item.recipes and item.recipes.workbenches then
                -- "", "PRINT_ITEMS") -- Empty line for readability
                -- "RECIPE INFORMATION:", "PRINT_ITEMS")
                
                for recipeName, recipe in pairs(item.recipes.workbenches) do
                    -- "  Recipe: " .. recipeName, "PRINT_ITEMS")
                    -- "  Workbench: " .. (recipe.workbench or "Unknown"), "PRINT_ITEMS")
                    -- "  Recipe Labor Cost: " .. (recipe.laborCost or 0) .. " LP", "PRINT_ITEMS")
                    -- "  Default Recipe: " .. (recipe.default and "Yes" or "No"), "PRINT_ITEMS")
                    
                    -- Materials
                    if recipe.materials and type(recipe.materials) == "table" then
                        -- "", "PRINT_ITEMS")
                        -- "  MATERIALS:", "PRINT_ITEMS")
                        
                        local materialCount = 0
                        for stringKey, matData in pairs(recipe.materials) do
                            materialCount = materialCount + 1
                            local buyStatus = matData.buy and "BUY" or "CRAFT"
                            local actualId = matData.id or stringKey:gsub("id_", "")  -- Extract ID from string key or use stored ID
                            -- "    " .. materialCount .. ". " .. (matData.name or "Unknown") .. " (ID: " .. actualId .. ")", "PRINT_ITEMS")
                            -- "       Amount: " .. (matData.amount or 0), "PRINT_ITEMS")
                            -- "       Decision: " .. buyStatus, "PRINT_ITEMS")
                        end
                        
                        if materialCount == 0 then
                            -- "    No materials found", "PRINT_ITEMS")
                        end
                    else
                        -- "    No materials data", "PRINT_ITEMS")
                    end
                end
            else
                -- "", "PRINT_ITEMS")
                -- "No recipe information available", "PRINT_ITEMS")
            end
            
            -- "", "PRINT_ITEMS") -- Empty line between items
        end
        
        -- "=== END OF ITEM INFORMATION ===", "PRINT_ITEMS")
        api.Log:Info("Finished printing all item information to debug log")
    end

    function window:Open(savedata)
        -- "Opening main window", "ITEM_WINDOW")
        api.Log:Info("Item window opened")
        
        -- Don't create multiple windows
        if mainWindow then
            mainWindow:Show(true)
            return
        end
        
        -- Create the main UI window
        mainWindow = api.Interface:CreateWindow("cashMoneyMain", "Cash Money Calculator", 1400, 600)
        
        
        -- Center the window on screen
        mainWindow:AddAnchor("CENTER", "UIParent", 0, 0)
        
        mainWindow:Show(true)
        
        -- Process all items and create the data grid
        -- "Loading and processing all item data", "WINDOW_OPEN")
        local itemData = ProcessSavedItemsForUI()  -- Use our new function to process saved data
        
        -- Create search input box above the data grid
        -- "Creating search input box", "UI_CREATION")
        
        local searchBox = gui.AddEditBox(
            mainWindow,                          -- parent window
            "itemSearchBox",                     -- unique ID
            "TOPLEFT",                          -- anchor point
            mainWindow,                         -- anchor target
            10, 50,                              -- x, y offset
            300, 25,                            -- width, height
            100,                                -- max characters
            "",                                 -- initial text
            "Item Name:",                       -- label text
            nil,                                -- tooltip (optional)
            0,                                  -- numeric type (0 = string)
            FONT_SIZE.LARGE,                                 -- font size
            function(_, text)                   -- onChange callback
                -- Reference the label that will be created below
                local matchLabel = mainWindow.matchLabel
                
                if text and string.len(text) > 2 then
                    -- "Searching for: " .. text, "ITEM_SEARCH")
                    local matches = GetItemByNameOrId(text, "search")
                    
                    if #matches > 0 then
                        -- "Found " .. #matches .. " matches", "ITEM_SEARCH")
                        -- Show best match in label
                        local bestMatch = matches[1]
                        local priorityText = bestMatch.priority == 1 and "EXACT" or "PARTIAL"
                        if matchLabel then
                            matchLabel:SetText("Found: " .. bestMatch.name .. " (ID: " .. string.format("%.0f", bestMatch.id) .. ") [" .. priorityText .. "]")
                        end
                        
                        -- Log first few matches with priority indicator
                        for i = 1, math.min(5, #matches) do
                            local priorityLog = matches[i].priority == 1 and "[EXACT]" or "[PARTIAL]"
                            -- "  " .. priorityLog .. " " .. matches[i].name .. " (ID: " .. matches[i].id .. ")", "ITEM_SEARCH")
                        end
                    else
                        if matchLabel then
                            matchLabel:SetText("No matches found for: " .. text)
                        end
                        -- "No matches found for: " .. text, "ITEM_SEARCH")
                    end
                else
                    if matchLabel then
                        matchLabel:SetText("Type to search for items...")
                    end
                end
            end
        )
        
        -- Create a label to show the best match (store reference on mainWindow)
        matchLabel = gui.AddLabel(
            mainWindow,                     -- parent window
            "matchLabel",                   -- unique ID
            "Type to search for items...",  -- initial text
            "LEFT",                         -- anchor to left of search box
            searchBox,                      -- anchor target
            320,                            -- x offset (right of 300px search box + 10px gap)
            0,                              -- y offset (same level as search box)
            FONT_SIZE.LARGE,               -- font size
            3,                             -- align type
            {1, 1, 1, 1},                  -- font color (white)
            10                             -- minimal padding
        )
        
        -- Create Add Item button using correct parameter format
        local addButton = gui.AddButton(
            mainWindow,                     -- parent window
            "addItemButton",               -- unique ID
            "Add Item",                    -- button text
            "LEFT",                        -- anchor point
            searchBox,                    -- anchor target
            0, 40,                         -- x offset, y offset
            nil,                           -- skin (default)
            function(buttonSelf)           -- onClick handler
                local searchText = searchBox:GetText()
                if searchText and searchText ~= "" and searchText ~= "Enter item name to search..." then
                    -- "Add button clicked for: " .. searchText, "ADD_ITEM_UI")
                    
                    -- Use existing AddItemToList function (maintains single source of truth)
                    local bestMatch = GetItemByNameOrId(searchText, "best_match")
                    local success = false
                    
                    if bestMatch then
                        -- "Found best match: " .. bestMatch.name .. " (ID: " .. bestMatch.id .. ")", "DEBUG")
                        
                        -- Check for duplicate ID in the cached item list
                        local isDuplicate = false
                        if cachedItemList then
                            -- "Checking duplicates in cached list with " .. #cachedItemList .. " items", "DEBUG")
                            for _, existingItem in ipairs(cachedItemList) do
                                if existingItem.id == bestMatch.id then
                                    isDuplicate = true
                                    -- "Duplicate item ID found! Item '" .. existingItem.name .. "' (ID: " .. bestMatch.id .. ") already exists in the list", "DEBUG")
                                    api.Log:Info("Duplicate item: " .. existingItem.name .. " already in list")
                                    break
                                end
                            end
                        else
                            -- "No cached list to check for duplicates", "DEBUG")
                        end
                        
                        if not isDuplicate then
                            -- "No duplicate found, calling AddItemToList(" .. bestMatch.id .. ")", "DEBUG")
                            success = AddItemToList(bestMatch.id)
                            -- "AddItemToList returned: " .. tostring(success), "DEBUG")
                        else
                            -- "Skipping add due to duplicate", "DEBUG")
                        end
                    else
                        -- "No match found for: " .. searchText, "ADD_ITEM_UI")
                    end
                    
                    if success then
                        -- "Add success, starting refresh process", "DEBUG")
                        
                        -- Refresh the data grid with updated item list using our new function
                        local newItemData = ProcessSavedItemsForUI()
                        -- "Got " .. #newItemData .. " items from ProcessSavedItemsForUI", "DEBUG")
                        
                        if mainWindow.itemList then
                            -- "Calling UpdateData on scroll list", "DEBUG")
                            mainWindow.itemList:UpdateData(newItemData)
                            -- "UpdateData completed", "DEBUG")
                            api.Log:Info("Item added and data grid refreshed")
                        else
                            -- "ERROR: mainWindow.itemList is nil!", "DEBUG")
                        end
                        
                        -- Clear the search box after successful add
                        searchBox:SetText("")
                        if mainWindow.matchLabel then
                            mainWindow.matchLabel:SetText("Type to search for items...")
                        end
                        -- "Cleared search box after successful add", "UI_CLEAR")
                    else
                        -- "Failed to add item: " .. searchText, "ADD_ITEM_UI")
                    end
                else
                    -- "No item selected to add", "ADD_ITEM_UI")
                end
            end,
            100, 25                        -- width, height
        )
        
        -- Create Add Item button using correct parameter format
        local updateMarketButton = gui.AddButton(
            mainWindow,                     -- parent window
            "updateMarketButton",               -- unique ID
            "Update Market Data",                    -- button text
            "LEFT",                        -- anchor point
            addButton,                    -- anchor target
            100, 0,                         -- x offset, y offset
            nil,                           -- skin (default)
            function(buttonSelf)           -- onClick handler
               log("We clicked the Update Market button", "UPDATE_MARKET")
               
               -- Use cached market data for now
               log("Using current market data", "UPDATE_MARKET")
               local freshMarketData = marketdata
               
               -- Read current item list
               local existingData = api.File:Read(config.files.itemList) or {}
               if not existingData or #existingData == 0 then
                   log("No items found in list to update", "UPDATE_MARKET")
                   return
               end
               
               local updatedCount = 0
               
               -- Update each item with ReadMarketData using fresh market data
               for i, item in ipairs(existingData) do
                   if item.id then
                       local newCost, newValue, newProfit = ReadMarketData(item, freshMarketData)
                       
                       -- Update the item with new values
                       item.cost = newCost
                       item.value = newValue
                       item.profit = newProfit
                       
                       updatedCount = updatedCount + 1
                       log("Updated " .. item.name .. " - Cost: " .. string.format("%.4f", newCost) .. ", Value: " .. string.format("%.4f", newValue) .. ", Profit: " .. string.format("%.4f", newProfit), "UPDATE_MARKET")
                   end
               end
               
               -- Save updated data back to file
               if updatedCount > 0 then
                   api.File:Write(config.files.itemList, existingData)
                   
                   -- Clear cache so UI will reload fresh data
                   cachedItemList = nil
                   
                   -- Refresh the UI display
                   local newItemData = ProcessSavedItemsForUI()
                   if mainWindow.itemList then
                       mainWindow.itemList:UpdateData(newItemData)
                   end
                   
                   log("Successfully updated " .. updatedCount .. " items and refreshed UI", "UPDATE_MARKET")
               end
            end,
            100, 25                        -- width, height
        )
        


        -- PrintAllItemInfo()  -- Commented out for performance - use Print Info button instead
        -- Always create the main data grid (even with 0 items)
        CreateMainDataGrid(itemData, "TOPLEFT", searchBox, -75, 100)
        -- "Created data grid with " .. #itemData .. " items", "WINDOW_OPEN")

        
    end

    -- Define the Close method
    function window:Close()
        -- "Closing main window", "ITEM_WINDOW")
        api.Log:Info("Item window closed")
        
        -- Close the actual UI window if it exists
        if mainWindow then
            mainWindow:Show(false)
            mainWindow = nil
        end
    end


    return window
end



    