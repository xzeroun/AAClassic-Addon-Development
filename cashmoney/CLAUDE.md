# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "Cash Money", a World of Warcraft addon for the AAClassic server. It's a materials cost calculator that helps players analyze crafting recipes and determine profitability by breaking down items into raw materials and calculating costs based on auction house data.

## Architecture

### Core Structure

- **main.lua**: Entry point and main addon logic. Contains the addon registration, global configuration, and core material processing algorithms
- **gui.lua**: Comprehensive UI library with reusable components (buttons, labels, checkboxes, editboxes, scroll lists, tree views)
- **windows/item_window.lua**: Main application window with item management, recipe analysis, and the interactive recipe editor
- **windows/recipe_window.lua**: Minimal file (currently empty)
- **data/**: Directory for persistent storage of item lists, recipe preferences, and settings

### Key Dependencies

- **Game API**: Uses `api` module for World of Warcraft interface integration (items, crafting, file I/O, logging)
- **Market Data**: Integrates with `your_paystub/data/auction_house_prices` for auction house pricing data

### Data Flow

1. **Item Addition**: Users input item IDs → system processes crafting recipes recursively → calculates raw material costs
2. **Recipe Analysis**: Uses `processMaterials()` function to traverse crafting trees and identify base materials
3. **Cost Calculation**: Combines raw material quantities with auction house pricing data
4. **Persistence**: Saves item lists and recipe preferences to lua files via `api.File:Write()`

### File Persistence

- `cashmoney\data\item_list.lua`: Saved items with calculated costs/profits
- `cashmoney\data\recipe_list.lua`: User preferences for buy vs craft decisions
- Uses Lua table serialization for data storage

### UI Components

The `gui.lua` module provides a complete UI toolkit:

- **AddButton()**: Customizable buttons with event handlers
- **AddLabel()**: Text labels with alignment and styling options  
- **AddCheckbox()**: Multi-style checkboxes with state management
- **AddEditBox()**: Text input fields with validation callbacks
- **AddScrollList()**: Advanced data grids with sorting, pagination, and custom cell layouts
- **AddTreeView()**: Hierarchical data displays

### Recipe Processing

- **Excluded Items**: Certain items (essences, coin) are treated as raw materials rather than craftable
- **Recursive Processing**: `buildItemNode()` creates hierarchical recipe trees
- **Buy/Craft Decisions**: Users can toggle whether to buy or craft each component
- **Tree Expansion**: Interactive UI for exploring recipe hierarchies

### Recipe Data Format & Loading

- **Save Format**: Nested structure where each recipe entry contains a materials array with all components
- **Load Format**: Flattened lookup map (id -> {name, buy}) for efficient tree building
- **Data Flow**: `saveRecipeButton` writes nested format → `loadRecipeData()` converts to flat map → `buildItemNode()` applies preferences
- **Compatibility**: Handles both legacy flat format and current nested format for backward compatibility
- **Highlighting**: Green text for "buy" items, red text for "craft" items in recipe editor

## Development Notes

- No build/test/lint commands - this is a pure Lua addon for World of Warcraft
- Development workflow involves editing .lua files and testing in-game
- Uses WoW addon API patterns and global namespace management
- File paths use Windows-style backslashes for API compatibility
- Extensive logging via `api.Log:Info()` for debugging

## Common Tasks

- **Adding Items**: Use the item ID input field in the main window
- **Recipe Analysis**: Click "Edit" button on any item to open recipe tree editor
- **Cost Calculation**: Based on `processMaterials()` recursive algorithm
- **Data Persistence**: Auto-saves item lists; recipe preferences saved via "Save" button in recipe editor
- **UI Customization**: Modify `gui.lua` helper functions for consistent styling across the addon
- First I need you to read everything in my api-source file as it contains the addon api the game exposes. This will help you give me better suggestions. Please never forget the information within these files.
- My envioronment doesnt allow os.date or any os lib functions. Please dont include it.
- Only use log to log stuff, dont ever use api.Log:Info by itself
- NEVER RETURN TABLES AS STRING... Always as LUA table!