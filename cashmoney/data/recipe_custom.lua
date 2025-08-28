{
    -- Bound Serendipity Stone - Alternative Regal Alchemy Table recipe
    ["8001000"] = {
        ["Regal Alchemy Table"] = {
            labor = 100,
            required_actability_name = "Alchemy", 
            required_actability_level = 180000,
            doodad_name = "Regal Alchemy Table",
            materials = {
                -- Note: You'll need to find the actual item IDs for these materials
                {itemType = 31929, amount = 5, name = "Starpoint"},           -- Replace 0 with actual ID
                {itemType = 16323, amount = 1, name = "Rising Star Stone"},   -- Replace 0 with actual ID  
                {itemType = 32038, amount = 150, name = "Earthmana Leaf"}     -- Replace 0 with actual ID
            }
        }
    }
    
    -- Add more custom recipes here as needed
    -- ["another_item_id"] = {
    --     ["Another Workbench"] = {
    --         labor = 50,
    --         required_actability_name = "Metalwork",
    --         required_actability_level = 50000,
    --         doodad_name = "Another Workbench",
    --         materials = {
    --             {itemType = 123, amount = 2, name = "Iron Ingot"},
    --             {itemType = 456, amount = 1, name = "Coal"}
    --         }
    --     }
    -- }
}