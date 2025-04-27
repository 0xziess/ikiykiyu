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
    enchant = {},
    pet = {},
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


-- Enchanting Tab Sections
local TriggerSection = CombatTab:AddSection("Enchanting")
TriggerSection:AddToggle("Auto Enchant", false, function(value)
    print("Trigger Bot:", value)
end)
local enchantOptions = {" Team Up I", "Team Up II", " Team Up III", " Team Up IV", " Team Up V", "  High Roller"}
TriggerSection:AddDropdown("Enchant", enchantOptions, "", function(selected)
    selectedStates.enchant
end)
TriggerSection:AddDropdown("Pet (Equipped in order)", {"pet1", "pet2", "pet3"}, "", function(selected)
    selectedStates.pet
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
