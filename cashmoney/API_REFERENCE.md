# ArcheAge Classic API Reference

This file documents the ArcheAge Classic addon API functions discovered while building the Cash Money addon.

## Table of Contents
- [Craft APIs](#craft-apis)
- [Item APIs](#item-apis)
- [File I/O APIs](#file-io-apis)
- [UI APIs](#ui-apis)
- [GUI System (gui.lua)](#gui-system-guilua)
- [Labor System](#labor-system)
- [Profession APIs](#profession-apis)
- [Debug Information](#debug-information)

## Craft APIs

### `api.Craft:GetCraftTypeByItemType(itemType)`
- **Purpose**: Gets the craft type ID for a given item type
- **Parameters**: `itemType` (number) - The item's type ID
- **Returns**: `craftType` (number) - The craft type ID, or nil if item is not craftable
- **Example**: `local craftType = api.Craft:GetCraftTypeByItemType(16325)` → `78`

### `api.Craft:GetCraftBaseInfo(craftType)`
- **Purpose**: Gets detailed crafting information for a craft type
- **Parameters**: `craftType` (number) - The craft type ID
- **Returns**: Table with crafting details
- **Key Properties**:
  - `consume_lp` (number) - Labor points consumed when crafting
  - `needed_lp` (number) - Labor points needed (same as consume_lp)
  - `skill_type` (number) - Required skill type ID
  - `cast_delay` (number) - Crafting time in milliseconds
  - `doodad_name` (string) - Required workbench (e.g., "Smelter")
  - `required_actability_name` (string) - Required profession (e.g., "Metalwork")
  - `required_actability_type` (number) - Profession type ID
  - `title` (string) - Recipe name
  - `laborpower_satisfied` (boolean) - Whether player has enough labor
  - `actability_satisfied` (boolean) - Whether player meets profession requirements

### `api.Craft:GetCraftMaterialInfo(craftType)`
- **Purpose**: Gets list of materials required for crafting
- **Parameters**: `craftType` (number) - The craft type ID
- **Returns**: Array of material objects
- **Material Object Properties**:
  - `item_info` (table) - Full item information
    - `itemType` (number) - Material's item type ID
    - `name` (string) - Material name
    - `cost`, `grade`, `category`, etc. - Full item details
  - `amount` (number) - Quantity of this material needed
  - `count` (number) - Current count in inventory
  - `mainGrade` (boolean) - Whether this affects final item grade

### `api.Craft:GetCraftProductInfo(craftType)`
- **Purpose**: Gets information about what the recipe produces
- **Parameters**: `craftType` (number) - The craft type ID
- **Returns**: Array of product objects
- **Product Object Properties**:
  - `itemType` (number) - Produced item type ID
  - `item_name` (string) - Produced item name
  - `amount` (number) - Quantity produced
  - `success_rate` (number) - Crafting success rate percentage
  - `productGrade` (number) - Grade of produced item
  - `useGrade` (boolean) - Whether grade affects the product

## Item APIs

### `api.Item:GetItemInfoByType(itemType)`
- **Purpose**: Gets comprehensive information about an item
- **Parameters**: `itemType` (number) - The item's type ID
- **Returns**: Table with item details
- **Key Properties**:
  - `name` (string) - Item display name
  - `description` (string) - Item description
  - `cost` (number) - Base item cost
  - `grade` (string) - Item grade ("Basic", "Arcane", etc.)
  - `category` (string) - Item category ("Metal", "Material", etc.)
  - `maxStack` (number) - Maximum stack size
  - `sellable` (boolean) - Whether item can be sold
  - `level` (number) - Item level
  - `path` (string) - Icon file path

## File I/O APIs

### `api.File:Write(filename, data)`
- **Purpose**: Writes data to a file in the addon directory
- **Parameters**: 
  - `filename` (string) - File path relative to addon folder
  - `data` (any) - Data to write (tables are serialized)
- **Returns**: `success` (boolean) - Whether write operation succeeded
- **Example**: `api.File:Write("cashmoney\\data\\debug.lua", "Hello World")`

### `api.File:Read(filename)`
- **Purpose**: Reads data from a file in the addon directory
- **Parameters**: `filename` (string) - File path relative to addon folder
- **Returns**: Data from file (tables are deserialized), or nil if file doesn't exist
- **Example**: `local data = api.File:Read("cashmoney\\data\\item_list.lua")`

## UI APIs

### `api.Interface:CreateWindow(id, title)`
- **Purpose**: Creates a new UI window
- **Parameters**: 
  - `id` (string) - Unique window identifier
  - `title` (string) - Window title bar text
- **Returns**: Window object
- **Methods**: `SetExtent()`, `AddAnchor()`, `Show()`, `CreateChildWidget()`

### `W_CTRL.CreateMultiLineEdit(id, parent)`
- **Purpose**: Creates a multiline text edit widget
- **Parameters**:
  - `id` (string) - Widget identifier
  - `parent` (widget) - Parent widget
- **Returns**: Text edit widget
- **Methods**: `SetText()`, `GetText()`, `SetExtent()`, `SetMaxTextLength()`

### `api.Interface:ApplyButtonSkin(button, skinType)`
- **Purpose**: Applies visual styling to buttons
- **Parameters**:
  - `button` (widget) - Button widget to style
  - `skinType` (constant) - Skin type (e.g., `BUTTON_BASIC.DEFAULT`)

## GUI System (gui.lua)

The gui.lua module provides a comprehensive UI generation system with reusable components and consistent styling. All functions are designed to work together and follow common patterns for anchoring, sizing, and event handling.

### Core Components

### `gui.AddButton(parent, name, text, anchorPoint, relativeTo, offsetX, offsetY, skin, clickFunc, width, height)`
- **Purpose**: Creates a styled button with full customization options
- **Parameters**:
  - `parent` (widget) - Parent window for the button
  - `name` (string) - Unique identifier, stored as parent[name]
  - `text` (string, optional) - Button text
  - `anchorPoint` (string, optional) - Anchor point ("TOPLEFT", "CENTER", etc.)
  - `relativeTo` (widget, optional) - Widget to position relative to
  - `offsetX, offsetY` (number, optional) - Position offsets in pixels
  - `skin` (constant/string, optional) - Visual style or string shortcut
  - `clickFunc` (function, optional) - Click callback function(button, args)
  - `width, height` (number, optional) - Dimensions in pixels
- **String Shortcuts**: "default", "plus", "minus", "close", "settings"
- **Example**: `gui.AddButton(window, "saveBtn", "Save", "BOTTOM", window, 0, -10, "default", function(btn) api.Log:Info("Saved!") end)`

### `gui.AddLabel(parent, name, text, anchorPoint, relativeTo, offsetX, offsetY, fontSize, align, color, padding)`
- **Purpose**: Creates a text label with automatic width sizing
- **Parameters**:
  - `parent` (widget) - Parent window
  - `name` (string) - Unique identifier
  - `text` (string) - Label text content
  - Positioning parameters (same as AddButton)
  - `fontSize` (number, optional) - Font size constant
  - `align` (number/string, optional) - Text alignment (1/"left", 2/"center", 3/"right")
  - `color` (table, optional) - FONT_COLOR constant
  - `padding` (number, optional) - Extra width padding (default: 14)
- **Features**: Auto-resizes on text changes, supports alignment shortcuts
- **Example**: `gui.AddLabel(window, "title", "My Application", "TOP", window, 0, 10, FONT_SIZE.LARGE, "center", FONT_COLOR.WHITE)`

### `gui.AddCheckbox(parent, id, text, checked, anchorPoint, relativeTo, offsetX, offsetY, padding, style, labelSide, fontSize)`
- **Purpose**: Creates a checkbox with optional text label
- **Parameters**:
  - `parent` (widget) - Parent window
  - `id` (string) - Unique identifier
  - `text` (string, optional) - Label text
  - `checked` (boolean, optional) - Initial state
  - Positioning parameters
  - `padding` (number, optional) - Space between checkbox and label
  - `style` (string, optional) - Visual style
  - `labelSide` (string, optional) - "left" or "right" label placement
  - `fontSize` (number, optional) - Font size for label
- **Styles**: "eyeShape", "soft_brown", "quest_notifier", "tutorial", nil (default)
- **Methods**: `SetOnCheckChanged(callback)`, `GetLabelText()`, `SetEnableCheckButton(enable)`
- **Example**: `gui.AddCheckbox(panel, "option1", "Enable Feature", false, "TOP", panel, 0, 20):SetOnCheckChanged(function(checked, widget) api.Log:Info("Feature " .. (checked and "on" or "off")) end)`

### `gui.AddEditBox(parent, name, anchorPoint, relativeTo, offsetX, offsetY, width, height, maxLength, defaultText, labelText, skin, labelOffsetY, fontSize, onTextChange)`
- **Purpose**: Creates a text input field with optional label
- **Parameters**:
  - `parent` (widget) - Parent window
  - `name` (string) - Unique identifier
  - Positioning and sizing parameters
  - `maxLength` (number, optional) - Character limit
  - `defaultText` (string, optional) - Initial text
  - `labelText` (string, optional) - Creates a label if provided
  - `skin` (constant, optional) - Visual styling
  - `labelOffsetY` (number, optional) - Vertical alignment adjustment
  - `fontSize` (number, optional) - Font size
  - `onTextChange` (function, optional) - Text change callback function(widget, newText)
- **Features**: Auto-positioning with labels, character limits, change notifications
- **Example**: `gui.AddEditBox(panel, "itemId", "TOPLEFT", panel, 10, 50, 120, 25, 10, "12345", "Item ID:")`

### `gui.AddScrollList(parent, id, columns, anchorInfo, dimensions, options)`
- **Purpose**: Creates an advanced sortable data grid with pagination
- **Parameters**:
  - `parent` (widget) - Parent window
  - `id` (string) - Unique identifier
  - `columns` (table array) - Column definitions (see below)
  - `anchorInfo` (table) - {point, relativeTo, offsetX, offsetY}
  - `dimensions` (table) - {width, height} (can be functions)
  - `options` (table, optional) - Additional configuration
- **Column Definition**: Each column object contains:
  - `name` (string) - Display name for header
  - `width` (number) - Column width in pixels
  - `setFunc` (function) - Cell population function(subItem, rowData, setValue)
  - `layoutFunc` (function, optional) - Custom cell layout creator
  - `disableSort` (boolean, optional) - Disable sorting for this column
- **Options**:
  - `rowCount` (number) - Visible rows (default: 20)
  - `enableColumns` (boolean) - Clickable headers (default: false)
  - `enablePagination` (boolean) - Enable pagination (default: true)
  - `pageSize` (number) - Items per page (default: 1000)
- **Data Management Methods**:
  - `UpdateData(dataArray)` - Replace all data
  - `AddRow(dataObject)` - Add single row
  - `DeleteRow(rowIndex)` - Remove row
  - `ClearData()` - Clear all data
  - `SortByColumn(columnIndex, ascending)` - Sort by column
- **Features**: Intelligent number sorting, custom cell layouts, pagination, search filtering
- **Example**:
```lua
local columns = {
    {name = "ID", width = 60, setFunc = function(item, data, setValue) 
        if setValue then item:SetText(tostring(data.id)) end 
    end},
    {name = "Name", width = 120, setFunc = function(item, data, setValue) 
        if setValue then item:SetText(data.name) end 
    end}
}
local dataList = gui.AddScrollList(window, "playerList", columns,
    {point = "TOPLEFT", relativeTo = window, offsetX = 10, offsetY = 50},
    {width = 400, height = 300}
)
```

### `gui.AddTreeView(parent, id, anchorConfig, sizeConfig, options, data, builderFunc)`
- **Purpose**: Creates a hierarchical tree view for nested data
- **Parameters**:
  - `parent` (widget) - Parent window
  - `id` (string) - Unique identifier
  - `anchorConfig` (table) - Positioning configuration
  - `sizeConfig` (table) - {width, height}
  - `options` (table, optional) - Display options
  - `data` (table, optional) - Tree data
  - `builderFunc` (function, optional) - Data conversion function
- **Options**: `itemFontSize`, `childFontSize`, `color`, `rowHeight`
- **Data Format**: Array of {text, value, subTexts} objects
- **Use Cases**: Skill trees, recipe hierarchies, folder structures

### `gui.AddComboBox(parent, id, anchorPoint, relativeTo, offsetX, offsetY, width, height, options, selectedIndex, onSelectionChange)`
- **Purpose**: Creates a dropdown selection box
- **Parameters**: Standard positioning plus:
  - `options` (table) - Array of option strings
  - `selectedIndex` (number) - Initially selected option (1-based)
  - `onSelectionChange` (function) - Selection callback function(combo, index, text)
- **Methods**: `SetOptions(newOptions)`, `SetSelectedIndex(index)`, `GetSelectedIndex()`, `GetSelectedText()`

### Utility Functions

### `gui.GetTierColor(level)` / `gui.GetHierarchyDisplayName(node, isExpanded)` / `gui.GetStatusColor(node)`
- **Purpose**: Helper functions for consistent color coding and display formatting
- **Usage**: Used internally by tree views and hierarchical displays
- **GetTierColor**: Returns FONT_COLOR constants based on level (0=WHITE, 1=YELLOW, 2=ORANGE, 3=GRAY)
- **GetHierarchyDisplayName**: Formats tree node names with expansion indicators ([+], [-], ---)
- **GetStatusColor**: Returns GREEN for buy items, RED for craft items

### `gui.PrintControl(control, controlName)`
- **Purpose**: Debug utility to inspect widget methods and properties
- **Usage**: `gui.PrintControl(myWidget, "MyWidget")` - logs all available methods
- **Useful**: For discovering functionality on unfamiliar UI widgets

## Labor System

### Labor Cost Calculation
- **Source**: `api.Craft:GetCraftBaseInfo(craftType).consume_lp`
- **Formula**: `totalLabor = baseLaborCost × quantity`
- **Usage**: Used to calculate total labor needed for crafting recipes
- **Example**: Steel Sword (50 labor) × 2 quantity = 100 total labor

### Labor Properties
- `consume_lp` - Labor consumed when crafting (primary property to use)
- `needed_lp` - Labor needed (identical to consume_lp in most cases)
- `laborpower_satisfied` - Boolean indicating if player has sufficient labor

## Profession APIs

### `api.Player:GetGamePoints()`
- **Purpose**: Gets various player currency and progression points
- **Parameters**: None
- **Returns**: Table with multiple point types
- **Key Properties**:
  - `livingPoint` (number) - Current living points (profession points)
  - `livingPotionSkill` (number) - Living potion skill level (112045 in example)
  - `honorPoint` (number) - Honor points for PvP
  - `contributionPointStr` (string) - Contribution points
  - `leadershipPoint` (number) - Leadership points
  - `livingQuestPoint` (number) - Living quest completion points
- **Usage**: `livingPotionSkill` appears to be profession-related skill level

### `api.Player:GetCrimeInfo()`
- **Purpose**: Gets player crime/justice system information
- **Parameters**: None
- **Returns**: Table with crime data
- **Properties**:
  - `crimeScore` (number) - Current crime score
  - `crimePoint` (number) - Crime points
  - `crimeRecord` (number) - Crime record

### `api.Ability:GetUnitClassName("player")`
- **Purpose**: Gets player's combat class name
- **Parameters**: `"player"` (string) - Unit identifier
- **Returns**: `className` (string) - Combat class (e.g., "Darkrunner")
- **Usage**: Shows combat skill combination, not professions

### `api.Unit:UnitInfo("player")`
- **Purpose**: Gets comprehensive player statistics
- **Parameters**: `"player"` (string) - Unit identifier  
- **Returns**: Large table with combat statistics
- **Key Properties**: All combat-related stats (damage, armor, etc.)
- **Note**: Does not contain profession levels

### Status: Profession Levels Not Yet Found
- Combat class information available via `GetUnitClassName()`
- `livingPotionSkill` from `GetGamePoints()` may be profession-related
- Need to investigate if profession levels are in different API calls
- Possible candidates: Direct calls to X2Player functions or profession-specific APIs

## Debug Information

### Debug Functions Available
1. `debugItemProperties(scrollData)` - Explores all craft API properties
2. `debugProfessionAPIs()` - Tests profession/skill API calls
3. `appendToDebugLog(content, sessionName)` - Manages debug file output

### Debug File Location
- `cashmoney\data\debug.lua` - Main debug output file
- Cleared on addon startup, then appends debug sessions
- Contains full API exploration results for copying/analysis

## Usage Patterns

### Recipe Processing Workflow
1. `api.Craft:GetCraftTypeByItemType()` - Check if item is craftable
2. `api.Craft:GetCraftBaseInfo()` - Get labor cost and requirements
3. `api.Craft:GetCraftMaterialInfo()` - Get required materials
4. Recursively process each material through the same workflow
5. Calculate total costs and labor requirements

### Buy vs Craft Logic
- Items marked as "buy" have 0 labor cost and don't recurse into materials
- Items marked as "craft" include their labor cost and process all materials
- Labor calculations respect buy/craft decisions dynamically

## Constants and Enums

### Item Types
- `500` - Coin (always excluded from recipe processing)

### Font Colors  
- `FONT_COLOR.GREEN` - Buy items (in recipe editor)
- `FONT_COLOR.RED` - Craft items (in recipe editor)
- `FONT_COLOR.YELLOW` - Labor costs (in recipe editor)
- `FONT_COLOR.GRAY` - Disabled/unavailable items
- `FONT_COLOR.CYAN` - Labor costs (in main list)

### Button Skins
- `BUTTON_BASIC.DEFAULT` - Standard button appearance

## Notes

- All file paths use Windows-style backslashes (`\\`) for compatibility
- Table data is automatically serialized/deserialized by File API
- API calls may return nil for non-existent or invalid IDs
- Labor costs are always integers (no decimal labor points)
- Recipe processing excludes certain items via `excludedItems` table (essences, coin)

---

*Last Updated: 2025-08-25*
*Generated for Cash Money addon development*