local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xziess/ikiykiyu/refs/heads/main/test.lua"))()

local Window = UILibrary:CreateWindow("infinity ui")

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
    autocollectseason = false,
    rendering = false,
    disableparticles = false,
    lowgp = false,
    autorift = false,
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
local slider = {
    eggquan = "",
}

-- Auto Farm Tab Sections
local AimbotSection = CombatTab:AddSection("Auto Farming")
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

AimbotSection:AddToggle("Auto Collect Season", false, function(value)
    toggleStates.autocollectseason = value
end)
local function collectseasonpass()
    local args = {
        [1] = "ClaimSeason"
    }

    game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote.Event:FireServer(unpack(args))
end
Window:CreateTask(function()
    if toggleStates.autocollectseason then
        collectseasonpass()
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
-- Function to clean enchant names
local function CleanEnchantName(name)
    if type(name) ~= "string" then
        warn("CleanEnchantName received non-string input:", name, type(name))
        return ""
    end
    return name:gsub("[^%w%s]", "")
end

-- Function to trim whitespace
local function TrimWhitespace(str)
    return str:match("^%s*(.-)%s*$")
end

-- Function to get current enchants (directly accessing UI elements)
local function GetCurrentEnchants(petUUID)
    local success, result = pcall(function()
        -- Direct path to enchant titles - no need to open inventory or pet details
        local enchantTitle1 = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant1"].Title
        local enchantTitle2 = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant2"].Title

        return {
            enchantTitle1.Text,
            enchantTitle2.Text
        }
    end)

    if not success then
        warn("Failed to get current enchants for pet:", petUUID, result)
        return {}
    end

    return result
end

-- Improved auto enchant logic based on your working version
local function autoEnchantLogic()
    -- Check if pet is selected
    if not selectedStates.pet or selectedStates.pet == "" then
        print("No pet selected for enchanting.")
        return false
    end
    
    -- Get desired enchants from multi-dropdown
    local desiredEnchants = selectedStatesMulti.enchants
    if not desiredEnchants or #desiredEnchants == 0 then
        -- Fallback to single dropdown if multi is empty
        if selectedStates.enchant and selectedStates.enchant ~= "" then
            desiredEnchants = {selectedStates.enchant}
        else
            print("No desired enchants selected.")
            return false
        end
    end
    
    -- Debug output
    print("Selected pet:", selectedStates.pet)
    print("Desired enchants:")
    for _, enchant in ipairs(desiredEnchants) do
        print("  -", enchant)
    end
    
    -- Get current enchants
    local petUUID = selectedStates.pet
    local currentEnchants = GetCurrentEnchants(petUUID)
    
    if #currentEnchants > 0 then
        print("Current enchants:")
        for i, enchant in ipairs(currentEnchants) do
            print("  Slot", i, ":", enchant)
        end
        
        -- Check for matches
        local matchFound = false
        
        for _, currentEnchant in ipairs(currentEnchants) do
            -- Skip empty enchants
            if not currentEnchant or currentEnchant == "" or currentEnchant == "NIL" then
                continue
            end
            
            local cleanedCurrentEnchant = CleanEnchantName(currentEnchant)
            local trimmedCurrentEnchant = TrimWhitespace(cleanedCurrentEnchant):lower()
            
            for _, desiredEnchant in ipairs(desiredEnchants) do
                local cleanedDesiredEnchant = CleanEnchantName(desiredEnchant)
                local trimmedDesiredEnchant = TrimWhitespace(cleanedDesiredEnchant):lower()
                
                print("Comparing:", trimmedCurrentEnchant, "with:", trimmedDesiredEnchant)
                
                if trimmedCurrentEnchant == trimmedDesiredEnchant then
                    print("Desired enchant already obtained:", desiredEnchant)
                    matchFound = true
                    break
                end
            end
            
            if matchFound then
                break
            end
        end
        
        -- Reroll if no match found
        if not matchFound then
            print("No desired enchants found, rerolling for pet:", petUUID)
            
            local args = {
                "RerollEnchants",
                petUUID
            }
            
            -- Call the remote function
            local success, result = pcall(function()
                return game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote.Function:InvokeServer(unpack(args))
            end)
            
            if not success then
                warn("Error rerolling enchants:", result)
            else
                print("Successfully rerolled enchants")
            end
            
            return true
        else
            return false
        end
    else
        print("Failed to get current enchants for pet:", petUUID)
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
end, 0.01) -- Check every second

local enchantOptions = {" Team Up I", "Team Up II", " Team Up III", " Team Up IV", " Team Up V", "  High Roller"}
TriggerSection:AddMultiDropdown("Enchants", enchantOptions, {}, function(selectedEnchants)
    selectedStatesMulti.enchants = selectedEnchants
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
OptimizeSection:AddToggle("Low Graphics Mode", false, function(value)
    toggleStates.lowgp = value
    
    if value then
        -- Save current graphics settings before changing them
        local UserSettings = UserSettings()
        local GameSettings = UserSettings.GameSettings
        
        -- Store original quality level
        toggleStates.savedGraphicsQuality = settings().Rendering.QualityLevel
        
        -- Store original lighting effects states
        local lighting = game:GetService("Lighting")
        toggleStates.savedLightingProperties = {
            Brightness = lighting.Brightness,
            GlobalShadows = lighting.GlobalShadows,
            Technology = lighting.Technology,
            EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = lighting.EnvironmentSpecularScale
        }
        
        -- Store post-processing effects states
        if lighting:FindFirstChild("Bloom") then
            toggleStates.savedBloom = lighting.Bloom.Enabled
        end
        
        if lighting:FindFirstChild("Blur") then
            toggleStates.savedBlur = lighting.Blur.Enabled
        end
        
        if lighting:FindFirstChild("SunRays") then
            toggleStates.savedSunRays = lighting.SunRays.Enabled
        end
        
        if lighting:FindFirstChild("ColorCorrection") then
            toggleStates.savedColorCorrection = lighting.ColorCorrection.Enabled
        end
        
        if lighting:FindFirstChild("DepthOfField") then
            toggleStates.savedDepthOfField = lighting.DepthOfField.Enabled
        end
        
        -- Store terrain settings
        if workspace:FindFirstChild("Terrain") then
            toggleStates.savedTerrainProperties = {
                WaterReflectance = workspace.Terrain.WaterReflectance,
                WaterTransparency = workspace.Terrain.WaterTransparency,
                WaterWaveSize = workspace.Terrain.WaterWaveSize,
                WaterWaveSpeed = workspace.Terrain.WaterWaveSpeed
            }
        end
        
        -- Apply low graphics settings
        settings().Rendering.QualityLevel = 1
        
        -- Reduce lighting quality
        lighting.Brightness = lighting.Brightness * 0.8
        lighting.GlobalShadows = false
        lighting.Technology = Enum.Technology.Compatibility
        lighting.EnvironmentDiffuseScale = 0
        lighting.EnvironmentSpecularScale = 0
        
        -- Disable post-processing effects
        if lighting:FindFirstChild("Bloom") then
            lighting.Bloom.Enabled = false
        end
        
        if lighting:FindFirstChild("Blur") then
            lighting.Blur.Enabled = false
        end
        
        if lighting:FindFirstChild("SunRays") then
            lighting.SunRays.Enabled = false
        end
        
        if lighting:FindFirstChild("ColorCorrection") then
            lighting.ColorCorrection.Enabled = false
        end
        
        if lighting:FindFirstChild("DepthOfField") then
            lighting.DepthOfField.Enabled = false
        end
        
        -- Reduce terrain quality
        if workspace:FindFirstChild("Terrain") then
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 1
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
        end
        
        -- Reduce other rendering features
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        settings().Rendering.EagerBulkExecution = false
        settings().Rendering.QualityLevel = 1
        settings().Rendering.ReloadAssets = false
        
        print("Low Graphics Mode enabled - original settings saved")
    else
        -- Restore all saved settings
        if toggleStates.savedGraphicsQuality then
            settings().Rendering.QualityLevel = toggleStates.savedGraphicsQuality
        end
        
        -- Restore lighting properties
        local lighting = game:GetService("Lighting")
        if toggleStates.savedLightingProperties then
            for property, value in pairs(toggleStates.savedLightingProperties) do
                pcall(function()
                    lighting[property] = value
                end)
            end
        end
        
        -- Restore post-processing effects
        if toggleStates.savedBloom ~= nil and lighting:FindFirstChild("Bloom") then
            lighting.Bloom.Enabled = toggleStates.savedBloom
        end
        
        if toggleStates.savedBlur ~= nil and lighting:FindFirstChild("Blur") then
            lighting.Blur.Enabled = toggleStates.savedBlur
        end
        
        if toggleStates.savedSunRays ~= nil and lighting:FindFirstChild("SunRays") then
            lighting.SunRays.Enabled = toggleStates.savedSunRays
        end
        
        if toggleStates.savedColorCorrection ~= nil and lighting:FindFirstChild("ColorCorrection") then
            lighting.ColorCorrection.Enabled = toggleStates.savedColorCorrection
        end
        
        if toggleStates.savedDepthOfField ~= nil and lighting:FindFirstChild("DepthOfField") then
            lighting.DepthOfField.Enabled = toggleStates.savedDepthOfField
        end
        
        -- Restore terrain settings
        if toggleStates.savedTerrainProperties and workspace:FindFirstChild("Terrain") then
            for property, value in pairs(toggleStates.savedTerrainProperties) do
                pcall(function()
                    workspace.Terrain[property] = value
                end)
            end
        end
        
        -- Restore other rendering features to defaults
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.EagerBulkExecution = true
        settings().Rendering.ReloadAssets = true
        
        print("Low Graphics Mode disabled - original settings restored")
    end
end)
OptimizeSection:AddToggle("Disable Particles", false, function(value)
    toggleStates.disableparticles = value
    
    local function processParticles(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ParticleEmitter") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Sparkles") then
                child.Enabled = not value
            end
            processParticles(child)
        end
    end
    processParticles(workspace)
    if value and not toggleStates.particleConnection then
        toggleStates.particleConnection = workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or descendant:IsA("Fire") or descendant:IsA("Sparkles") then
                task.wait() -- Wait a frame to ensure it's fully added
                descendant.Enabled = false
            end
        end)
    elseif not value and toggleStates.particleConnection then
        toggleStates.particleConnection:Disconnect()
        toggleStates.particleConnection = nil
    end
end)

-- Visuals Tab Sections
local ESPSection = VisualsTab:AddSection("Rift")
ESPSection:AddToggle("Auto Rift", false, function(value)
    toggleStates.autorift = value
end)
local function ProcessEggModel(model, rootPos, eggsTable)
    local rootPart = model:FindFirstChild("Root") or model.PrimaryPart
    if rootPart then
        local distance = (rootPart.Position - rootPos).Magnitude
        if distance <= 30 then
            table.insert(eggsTable, model.Name)
            return true
        end
    end
    return false
end
local EggPositions = {
    ["Common Egg"] = Vector3.new(-8.070183753967285, 9.598024368286133, -82.37651062011719),
    ["Infinity Egg"] = Vector3.new(-99.70166015625, 8.598015785217285, -26.829652786254883),
    ["Nightmare Egg"] = Vector3.new(-18.746173858642578, 10148.1611328125, 186.91860961914062),
	["Void Egg"] = Vector3.new(4.745765209197998, 10148.1025390625, 187.00119018554688),
    ["Rainbow Egg"] = Vector3.new(-36.07754135131836, 15972.72265625, 45.21904754638672),
    ["100M Egg"] = Vector3.new(16.167966842651367, 9.530410766601562, -3.9539427757263184),
}
local RiftToEggMap = {
    ["void-egg"] = "Void Egg",
    ["rainbow-egg"] = "Rainbow Egg",
    ["nightmare-egg"] = "Nightmare Egg",
    ["silly-egg"] = "Silly Egg",
    ["man-egg"] = "Aura Egg",
}
local function getRiftLuck(rift)
    local displayPart = rift:FindFirstChild("Display")
    if not displayPart then return 0 end
    local surfaceGui = displayPart:FindFirstChild("SurfaceGui")
    if not surfaceGui then return 0 end
    local icon = surfaceGui:FindFirstChild("Icon")
    if not icon then return 0 end
    local luckLabel = icon:FindFirstChild("Luck")
    if not luckLabel or not luckLabel:IsA("TextLabel") then return 0 end
    local luckText = luckLabel.Text
    local match1 = string.match(luckText, "x(%d+)")
    if match1 then
        return tonumber(match1) or 0
    end
    local match2 = string.match(luckText, "(%d+)x")
    if match2 then
        return tonumber(match2) or 0
    end
    local match3 = string.match(luckText, "(%d+)")
    if match3 then
        return tonumber(match3) or 0
    end
    return 0
end
local lastHatchTime = 0
local HATCH_COOLDOWN = 1 -- seconds
local isAtHatchingLocation = false
local currentHatchingEgg = nil
local lastRKeyPress = 0
local R_KEY_INTERVAL = 0.001 -- Press R every 0.5 seconds
local function smoothTeleportTo(targetCFrame)
    local character = LP.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end

    local rootPart = character.HumanoidRootPart
    local startPos = rootPart.Position

    -- Calculate horizontal distance only
    local horizontalDistance = (Vector3.new(targetCFrame.X, 0, targetCFrame.Z) -
                                  Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
    local verticalDifference = math.abs(targetCFrame.Y - startPos.Y)

    -- NEW: Speed INCREASES with distance
    local teleportSpeed = math.clamp(30 + (horizontalDistance / 10), 5, 10)

    local tweenInfo = TweenInfo.new(
        horizontalDistance / teleportSpeed, -- Time = Distance / Speed
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()

    return tween
end
local function islandHatchLogic()
    local character = LP.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("Character or HumanoidRootPart not found.")
        isAtHatchingLocation = false
        return
    end

    local rootPart = character.HumanoidRootPart
    local riftsFolder = workspace:FindFirstChild("Rendered") and workspace.Rendered:FindFirstChild("Rifts")
    local selectedRifts = selectedStatesMulti.rifts or {}
    local selectedLuck = selectedStatesMulti.riftsLuck or {}
    
    -- Reset teleportation state
    isTeleporting = false
    targetPosition = nil
    local eggToHatch = nil

    -- First try to find matching rifts
    if riftsFolder and #selectedRifts > 0 then
        local bestRift = nil
        local highestLuck = 0

        for _, riftName in ipairs(selectedRifts) do
            local rift = riftsFolder:FindFirstChild(riftName)
            if rift then
                local riftLuck = getRiftLuck(rift)
                if riftLuck > 0 then
                    local luckStr = "x"..tostring(riftLuck)
                    if table.find(selectedLuck, luckStr) then
                        if riftLuck > highestLuck then
                            highestLuck = riftLuck
                            bestRift = rift
                            -- Determine which egg corresponds to this rift
                           eggToHatch = RiftToEggMap[riftName] or riftName:gsub("-rift", " Egg"):gsub("rift", " Egg")
                        end
                    end
                end
            end
        end

        if bestRift then
            local displayPart = bestRift:FindFirstChild("Display")
            if displayPart then
                targetPosition = displayPart.CFrame
                isTeleporting = true
                smoothTeleportTo(targetPosition)
                
                -- Auto-hatch the corresponding egg if close enough
                if (rootPart.Position - displayPart.Position).Magnitude < 15 then
                    -- Set hatching location state
                    isAtHatchingLocation = true
                    currentHatchingEgg = eggToHatch
                    
                    -- Press R key to open hatching interface
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                    task.wait(0.01)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                    
                    -- Send hatch request
                    Remote:FireServer("HatchEgg", eggToHatch, slider.eggquan)
                else
                    isAtHatchingLocation = false
                    currentHatchingEgg = nil
                end
                return
            end
        end
    end

    -- Fallback egg handling
    local fallbackEggName = selectedStates.fallbackEgg
    if fallbackEggName ~= "" then
        local fallbackEggPosition = EggPositions[fallbackEggName]
        if fallbackEggPosition then
            targetPosition = CFrame.new(fallbackEggPosition)
            isTeleporting = true
            smoothTeleportTo(targetPosition)
            
            -- Auto-hatch the fallback egg if close enough
            if (rootPart.Position - fallbackEggPosition).Magnitude < 15 then
                -- Set hatching location state
                isAtHatchingLocation = true
                currentHatchingEgg = fallbackEggName
                
                -- Press R key to open hatching interface
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                task.wait(0.001)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                
                -- Send hatch request
                Remote:FireServer("HatchEgg", fallbackEggName, slider.eggquan)
            else
                isAtHatchingLocation = false
                currentHatchingEgg = nil
            end
        else
            isAtHatchingLocation = false
            currentHatchingEgg = nil
        end
    else
        isAtHatchingLocation = false
        currentHatchingEgg = nil
    end
end
Window:CreateTask(function()
    if toggleStates.autorift and isAtHatchingLocation and currentHatchingEgg then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.001)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end
end, 0.001)
Window:CreateTask(function()
    if toggleStates.autorift then
        local success, result = pcall(islandHatchLogic)
        if not success then
            warn("Error in auto enchant logic:", result)
        end
    end
end, 0.1)

local FallbackEggOptions = {"Nightmare Egg", "Rainbow Egg", "Void Egg", "Common Egg", "Infinity Egg", "100M Egg"}
ESPSection:AddDropdown("Fallback Egg", FallbackEggOptions, "", function(selected)
    selectedStates.fallbackEgg = selected
end)
local RiftOptions = {"nightmare-egg", "rainbow-egg", "void-egg", "silly-egg", "man-egg"}
ESPSection:AddMultiDropdown("Rifts", RiftOptions, {}, function(selected)
    selectedStatesMulti.rifts = selected
end)
local RiftLuckOptions = {"x5", "x10", "x25"}
ESPSection:AddMultiDropdown("Rift's luck", RiftLuckOptions, {}, function(selected)
    selectedStatesMulti.riftsLuck = selected
end)
ESPSection:AddSlider("Egg Amount", 1, 6, 6, function(value)
    slider.eggquan = value
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

local configsect = MiscTab:AddSection("Config Management")
configsect:AddDropdown("Config name", {}, "", function(text)
end)
configsect:AddButton("Save", function()
end)
configsect:AddButton("Load", function()
end)
