local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xziess/ikiykiyu/refs/heads/main/test.lua"))()

local Window = UILibrary:CreateWindow("infinity.")

-- Create tabs
local CombatTab = Window:AddTab("Farming")
local VisualsTab = Window:AddTab("Rifts")
local MiscTab = Window:AddTab("Settings")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local Remote = ReplicatedStorage.Shared.Framework.Network.Remote.Event
local Pickup = ReplicatedStorage.Remotes.Pickups.CollectPickup

local toggleStates = {
    autoBlowEnabled = false,
    autoSellEnabled = false,
    autoCollectEnabled = false,
    autoEnchantEnabled = false,
}

local selectedStates = {
    enchant = "",
    pet = "",
    fallbackEgg = "",
    rift = "",
    riftLuck = ""
}

-- Auto Farm Tab Sections
local AimbotSection = CombatTab:AddSection("Auto")
AimbotSection:AddToggle("Auto Blow", false, function(value)
    toggleStates.autoBlowEnabled = value
end)
Window:CreateTask(function()
    if toggleStates.autoBlowEnabled then
        Remote:FireServer("BlowBubble")
    end
end, 0.01)

AimbotSection:AddToggle("Auto Sell (broken)", false, function(value)
    toggleStates.autoSellEnabled = value
end)
Window:CreateTask(function()
    if toggleStates.autoSellEnabled then
        Remote:FireServer("SellBubble")
        task.wait(1)
    end
end, 0.1)

AimbotSection:AddToggle("Auto Collect", false, function(value)
    toggleStates.autoCollectEnabled = value
end)
local function collectItems()
    local renderedFolder = workspace:FindFirstChild("Rendered")
    if renderedFolder then
        local correctChunkerFolder = nil

        -- Find the "Chunker" folder primarily containing collectible models
        for _, folder in ipairs(renderedFolder:GetChildren()) do
            if folder.Name == "Chunker" then
                local collectibleCount = 0
                local totalModelCount = 0
                for _, item in ipairs(folder:GetChildren()) do
                    if item:IsA("Model") then
                        totalModelCount += 1
                        if string.len(item.Name) >= 33 and string.len(item.Name) <= 37 then
                            collectibleCount += 1
                        end
                    end
                end

                -- Heuristic: If a significant portion (e.g., > 0.8) of models are collectibles, consider this the right folder
                if totalModelCount > 0 and (collectibleCount / totalModelCount) > 0.8 then
                    correctChunkerFolder = folder
                    break
                elseif totalModelCount > 0 and collectibleCount > 0 and totalModelCount == collectibleCount then -- Alternative: If all models are collectibles
                    correctChunkerFolder = folder
                    break
                end
            end
        end

        if correctChunkerFolder then
            for _, collectible in ipairs(correctChunkerFolder:GetChildren()) do
                if collectible:IsA("Model") and string.len(collectible.Name) >= 33 and string.len(collectible.Name) <= 37 then
                    local collectibleId = collectible.Name
                    pcall(function()
                        if Pickup then
                            local args = {
                                [1] = collectibleId
                            }
                            Pickup:FireServer(unpack(args)) -- Using unpack(args)
                            collectible:Destroy()
                        else
                            warn("RemoteEvent 'CollectPickup' is nil!")
                        end
                    end)
                    task.wait(0.15) -- Small delay AFTER firing the event
                end
            end
        else
            print("Could not identify the correct Chunker folder for collectibles.")
        end
    else
        print("workspace.Rendered NOT found.")
    end
end
Window:CreateTask(function()
    if toggleStates.autoCollectEnabled then
        collectItems()
    end
end, 0.1)

-- Enchanting Tab Sections
local TriggerSection = CombatTab:AddSection("Enchanting")
TriggerSection:AddToggle("Auto Enchant", false, function(value)
    print("Trigger Bot:", value)
end)
local enchantOptions = {" Team Up I", "Team Up II", " Team Up III", " Team Up IV", " Team Up V", "  High Roller"}
TriggerSection:AddDropdown("Enchant", enchantOptions, "", function(selected)
    selectedStates.enchant = selected
end)

_G.PetsData = {}
local function GetEquippedPetNames()
    local petData = {}
    
    local success, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local inventoryFrame = player.PlayerGui.ScreenGui.Inventory.Frame
        
        -- Check if the Inventory frame is visible
        if not inventoryFrame.Visible then
            -- Try to make it visible or return current data
            return _G.PetsData
        end
        
        local list = inventoryFrame.Inner.Pets.Main.ScrollingFrame.Team.Main.List
        
        for _, petFrame in ipairs(list:GetChildren()) do
            if petFrame:IsA("Frame") and petFrame.Name ~= "UIListLayout" then
                -- Get the UUID (original name with team suffix removed)
                local petUUID = petFrame.Name:gsub("-team%-?%d*", "")
                
                -- Try to get the display name from the UI
                local displayName = "Unknown Pet"
                local rarity = "Common" -- Default rarity
                local level = "1" -- Default level
                
                -- Use pcall to safely attempt to access the display name and other data
                pcall(function()
                    if petFrame.Inner.Button.Inner.DisplayName then
                        displayName = petFrame.Inner.Button.Inner.DisplayName.Text
                    end
                    
                    -- Try to get rarity if available
                    if petFrame.Inner.Button.Inner.Rarity then
                        rarity = petFrame.Inner.Button.Inner.Rarity.Text
                    end
                    
                    -- Try to get level if available
                    if petFrame.Inner.Button.Inner.Level then
                        level = petFrame.Inner.Button.Inner.Level.Text:match("Lv. (%d+)") or "1"
                    end
                end)
                
                -- Create a formatted display text
                local displayText = string.format("%s", displayName)
                
                -- Store the pet data
                table.insert(petData, {
                    uuid = petUUID,
                    name = displayName,
                    rarity = rarity,
                    level = level,
                    displayText = displayText
                })
            end
        end
        
        return petData
    end)
    
    if not success then
        warn("Failed to get equipped pets:", result)
        return _G.PetsData -- Return existing data on error
    end
    
    -- If no pets were found but we have existing data, return that
    if #result == 0 and #_G.PetsData > 0 then
        return _G.PetsData
    elseif #result == 0 then
        return {
            {uuid = "none", name = "No pets equipped", displayText = "No pets equipped"}
        }
    end
    
    -- Update the global pet data
    _G.PetsData = result
    
    return result
end
local function InitializePetDropdown()
    local petsData = GetEquippedPetNames()
    
    local petDisplayOptions = {}
    for _, pet in ipairs(petsData) do
        table.insert(petDisplayOptions, pet.displayText)
    end
    
    return petDisplayOptions
end
local petOptions = InitializePetDropdown()
TriggerSection:AddDropdown("Pet (Equipped in order)", petOptions, petOptions[1] or "", function(selected)
    -- Find the selected pet's data
    local selectedPetData = nil
    for _, pet in ipairs(_G.PetsData) do
        if pet.displayText == selected then
            selectedPetData = pet
            break
        end
    end
    
    -- Store the complete pet data
    if selectedPetData then
        selectedStates.pet = selectedPetData
    else
        selectedStates.pet = { displayText = selected, uuid = "unknown" }
    end
end)

-- Optimize Tab Sections
local OptimizeSection = CombatTab:AddSection("Optimization")
OptimizeSection:AddToggle("Disable 3D Rendering", false, function(value)
    print("3D:", value)
end)

-- Visuals Tab Sections
local ESPSection = VisualsTab:AddSection("Rift")
ESPSection:AddToggle("Auto Rift", false, function(value)
    print("Player ESP:", value)
end)
ESPSection:AddDropdown("Fallback Egg", {"ForceField", "Neon", "Plastic"}, "", function(selected)
    print("Chams Material:", selected)
end)
ESPSection:AddDropdown("Rifts", {"ForceField", "Neon", "Plastic"}, "", function(selected)
    print("Chams Material:", selected)
end)
ESPSection:AddDropdown("Rift's luck", {"ForceField", "Neon", "Plastic"}, "", function(selected)
    print("Chams Material:", selected)
end)
ESPSection:AddSlider("Egg Amount", 1, 6, 5, function(value)
    print("Aimbot FOV:", value)
end)

-- Misc Tab Sections
local ServerSection = MiscTab:AddSection("Server")
ServerSection:AddButton("Rejoin Server", function()
    print("Rejoining server...")
end)
ServerSection:AddButton("Server Hop", function()
    print("Server hopping...")
end)

local SettingsSection = MiscTab:AddSection("Settings")
SettingsSection:AddTextbox("Custom Name", "", "Enter name...", function(text)
    print("Custom Name:", text)
end)
SettingsSection:AddToggle("Auto-Execute", false, function(value)
    print("Auto-Execute:", value)
end)
