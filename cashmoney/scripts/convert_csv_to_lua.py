#!/usr/bin/env python3
import csv
import os

def convert_csv_to_lua():
    csv_file = "data/item_id_to_name.csv"
    lua_file = "data/item_id_to_name.lua"
    
    # Check if CSV file exists
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found!")
        return
    
    items = {}
    
    # Read CSV file
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            item_id = row['id'].strip()
            item_name = row['name'].strip()
            
            # Skip empty rows
            if not item_id or not item_name:
                continue
                
            # Convert ID to number and escape quotes in name
            try:
                items[int(item_id)] = item_name.replace('"', '\\"')
            except ValueError:
                print(f"Warning: Skipping invalid ID: {item_id}")
                continue
    
    # Write Lua file
    with open(lua_file, 'w', encoding='utf-8') as f:
        f.write("-- Auto-generated from item_id_to_name.csv\n")
        f.write("-- Item ID to Name lookup table\n")
        f.write("return {\n")
        
        # Sort by ID for cleaner output
        for item_id in sorted(items.keys()):
            item_name = items[item_id]
            f.write(f'    [{item_id}] = "{item_name}",\n')
        
        f.write("}\n")
    
    print(f"Successfully converted {len(items)} items to {lua_file}")
    print(f"Usage in addon: local itemData = require('cashmoney/data/item_id_to_name')")

if __name__ == "__main__":
    convert_csv_to_lua()