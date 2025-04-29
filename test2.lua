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
    rendering = false,
}
local selectedStates = {
    enchant = "",
    pet = "",
    fallbackEgg = "",
}
local selectedStatesMulti = {
    enchants = {},
    rifts = {},
    riftsLuck = {}
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
end, 0.01)

-- Enchanting Tab Sections
local TriggerSection = CombatTab:AddSection("Enchanting")

local function ResetEnchant()
    local success, result = pcall(function()
        local enchantTitle = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant1"].Title
		local enchantTitle2 = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant2"].Title
        enchantTitle.Text = "NIL"
		enchantTitle2.Text = "NIL"
        return enchantTitle.Text or enchantTitle2.Text
    end)

    if not success then
        warn("Failed to reset enchant display:", result)
        return nil
    end
    return result
end
TriggerSection:AddToggle("Auto Enchant", false, function(value)
    toggleStates.autoEnchantEnabled = value

    if toggleStates.autoEnchantEnabled then
        ResetEnchant()
    end
end)
local ENCHANT_COOLDOWN = 0.01
local function CleanEnchantName(name)
    if type(name) ~= "string" then
        warn("CleanEnchantName received non-string input:", name, type(name))
        return ""
    end

    -- Remove non-alphanumeric characters
    return name:gsub("[^%w%s]", "")
end
local function TrimWhitespace(str)
    return str:match("^%s*(.-)%s*$")
end
local function GetCurrentEnchants(petName)
    local success, result = pcall(function()
        -- Path to the pet's enchant titles
        local enchantTitle1 = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant1"].Title
        local enchantTitle2 = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant2"].Title

        -- Return both enchant title texts in a table
        return {
            enchantTitle1.Text,
            enchantTitle2.Text
        }
    end)

    if not success then
        warn("Failed to get current enchants for pet:", petName, result)
        return {}
    end

    return result
end
local function autoEnchantLogic()
    -- Check if pet is selected
    if not selectedStates.pet or selectedStates.pet == "unknown" then
        print("No pet selected for enchanting.")
        return false
    end
    
    -- Check if enchants are selected (now handling both single string and array)
    local desiredEnchants = {}
    
    -- Handle different possible formats of selectedStates.enchants
    if selectedStates.enchants then
        -- If it's already an array from multi-dropdown
        if type(selectedStates.enchants) == "table" then
            desiredEnchants = selectedStates.enchants
        else
            -- If it's a single string
            table.insert(desiredEnchants, selectedStates.enchants)
        end
    elseif selectedStates.enchant then
        -- For backward compatibility with old single-select dropdown
        if type(selectedStates.enchant) == "table" then
            desiredEnchants = selectedStates.enchant
        else
            table.insert(desiredEnchants, selectedStates.enchant)
        end
    end
    
    -- Ensure we have at least one enchant selected
    if #desiredEnchants == 0 then
        print("No desired enchants selected.")
        return false
    end
    
    -- Get the pet UUID
    local petUUID = selectedStates.pet
    
    print("Checking enchants for pet UUID:", petUUID)
    print("Desired enchants:", table.concat(desiredEnchants, ", "))
    
    -- Get current enchants for the pet
    local currentEnchants = GetCurrentEnchants(petUUID)
    
    if #currentEnchants > 0 then
        print("Current enchants for pet:")
        for i, enchant in ipairs(currentEnchants) do
            print("  Slot", i, ":", enchant)
        end
        
        -- Check if any of the desired enchants are already present
        local matchFound = false
        local matchedEnchant = ""
        
        -- For each current enchant on the pet
        for _, currentEnchant in ipairs(currentEnchants) do
            -- Skip empty or nil enchants
            if not currentEnchant or currentEnchant == "" or currentEnchant == "NIL" then
                continue
            end
            
            local cleanedCurrentEnchant = CleanEnchantName(currentEnchant)
            local trimmedCurrentEnchant = TrimWhitespace(cleanedCurrentEnchant):lower()
            
            -- Check against each desired enchant
            for _, desiredEnchant in ipairs(desiredEnchants) do
                local cleanedDesiredEnchant = CleanEnchantName(desiredEnchant)
                local trimmedDesiredEnchant = TrimWhitespace(cleanedDesiredEnchant):lower()
                
                print("Comparing:", trimmedCurrentEnchant, "with:", trimmedDesiredEnchant)
                
                if trimmedCurrentEnchant == trimmedDesiredEnchant then
                    print("Desired enchant already obtained:", desiredEnchant)
                    matchFound = true
                    matchedEnchant = desiredEnchant
                    break
                end
            end
            
            if matchFound then
                break
            end
        end
        
        -- If none of the desired enchants are found, reroll
        if not matchFound then
            print("None of the desired enchants found, rerolling...")
            
            local args = {
                "RerollEnchants",
                petUUID
            }

            -- Use pcall to handle potential errors
            local success, result = pcall(function()
                return game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote.Function:InvokeServer(unpack(args))
            end)
            
            if not success then
                warn("Error rerolling enchants:", result)
            end
            
            return true
        else
            print("Pet already has desired enchant:", matchedEnchant)
            return false
        end
    else
        print("Failed to get current enchants for pet")
        return false
    end
end
Window:CreateTask(function()
    if toggleStates.autoEnchantEnabled then
        local success, result = pcall(autoEnchantLogic)
        if not success then
            warn("Error in auto enchant logic:", result)
        end
    end
end, 1) -- Check every second

local enchantOptions = {" Team Up I", "Team Up II", " Team Up III", " Team Up IV", " Team Up V", "  High Roller"}
TriggerSection:AddDropdown("Enchant", enchantOptions, "", function(selected)
    selectedStatesMulti.enchants = selected
end)

local function GetEquippedPetNames()
    local petNames = {}
    local success, result = pcall(function()
        local inventoryFrame = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame

        -- Check if the Inventory frame is visible
        if inventoryFrame.Visible then
            local list = inventoryFrame.Inner.Pets.Main.ScrollingFrame.Team.Main.List

            for _, petFrame in ipairs(list:GetChildren()) do
                if petFrame.Name ~= "UIListLayout" then
                    -- Remove the "-team-X" part from the pet name
                    local petName = petFrame.Name:gsub("-team%-?%d*", "")
                    table.insert(petNames, petName)
                end
            end
        end
        return petNames
    end)

    if not success then
        warn("Failed to get equipped pets:", result)
        return {"Error loading pets"}
    end

    return petNames
end
TriggerSection:AddDropdown("Pet (Equipped in order)", GetEquippedPetNames(), "", function(selected)
    selectedStates.pet = selected
end)

-- Optimize Tab Sections
local OptimizeSection = CombatTab:AddSection("Optimization")
local function GPURenderingToggle(value)
    game:GetService("RunService"):Set3dRenderingEnabled(not value)
end
OptimizeSection:AddToggle("Disable 3D Rendering", false, function(value)
    toggleStates.rendering = value

    GPURenderingToggle(value)
end)

-- Visuals Tab Sections
local ESPSection = VisualsTab:AddSection("Rift")
ESPSection:AddToggle("Auto Rift", false, function(value)
end)
local FallbackEggOptions = {"Nightmare Egg", "Rainbow Egg", "Void Egg", "Common Egg", "Infinity Egg"}
ESPSection:AddDropdown("Fallback Egg", FallbackEggOptions, "", function(selected)
end)
local RiftOptions = {"nightmare-egg", "rainbow-egg", "void-egg"}
ESPSection:AddMultiDropdown("Rifts", RiftOptions, "", function(selected)
    selectedStatesMulti.rifts = selected
end)
local RiftLuckOptions = {"x5", "x10", "x25"}
ESPSection:AddMultiDropdown("Rift's luck", RiftLuckOptions, "", function(selected)
    selectedStatesMulti.riftsLuck = selected
end)
ESPSection:AddSlider("Egg Amount", 1, 6, 5, function(value)
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
