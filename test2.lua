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


-- Auto Farm Tab Sections
local AimbotSection = CombatTab:AddSection("Auto")
AimbotSection:AddToggle("Auto Blow", false, function(value)
    toggleStates.autoBlowEnabled = value
end)
task.spawn(function()
    while _G.UIRunning do
        if toggleStates.autoBlowEnabled then
            Remote:FireServer("BlowBubble")
        end
        task.wait(0.01)
    end
end)

AimbotSection:AddToggle("Auto Sell (broken)", false, function(value)
    toggleStates.autoSellEnabled = value
end)
task.spawn(function()
    while _G.UIRunning do
        if toggleStates.autoSellEnabled then
            Remote:FireServer("SellBubble")
            task.wait(1)
        end
        task.wait(0.1)
    end
end)

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

task.spawn(function()
    while _G.UIRunning do
        if toggleStates.autoCollectEnabled then
            collectItems()
        end
        task.wait(0.1)
    end
end)

-- Enchanting Tab Sections
local TriggerSection = CombatTab:AddSection("Enchanting")
TriggerSection:AddToggle("Auto Enchant", false, function(value)
    print("Trigger Bot:", value)
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
