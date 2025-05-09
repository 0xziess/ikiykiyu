local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xziess/ikiykiyu/refs/heads/main/test.lua"))()

local Window = UILibrary:CreateWindow("infinity ui")

-- Create tabs
local CombatTab = Window:AddTab("Farming")
local VisualsTab = Window:AddTab("Rifts")
local MiscTab = Window:AddTab("Settings")

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Player references
local LP = Players.LocalPlayer
local character = LP.Character or LP.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Remote references
local Remote = ReplicatedStorage.Shared.Framework.Network.Remote.Event
local Pickup = ReplicatedStorage.Remotes.Pickups.CollectPickup

-- State management
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
    antiafk = false,
    spamrkey = false,
    stuckpos = false,
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
    eggquan = 6,
}

local codes = {
    "free",
    "eventupdate",
    "thenewcode",
    "themystery",
    "icomilestone",
    "update",
    "sillyyes",
    "iwannapower",
    "bubbleproject",
    "freeall",
    "throwback",
}

-- Cache frequently used values
local lastAction = os.time()
local lastHatchTime = 0
local HATCH_COOLDOWN = 1
local isAtHatchingLocation = false
local currentHatchingEgg = nil
local lastRKeyPress = 0
local R_KEY_INTERVAL = 0.001
local lastRerollTime = 0
local REROLL_COOLDOWN = 0.01 -- seconds

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
    if not renderedFolder then 
        print("workspace.Rendered NOT found.")
        return 
    end

    local correctChunkerFolder
    for _, folder in ipairs(renderedFolder:GetChildren()) do
        if folder.Name == "Chunker" then
            local collectibleCount = 0
            local totalModelCount = 0
            
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Model") then
                    totalModelCount = totalModelCount + 1
                    if string.len(item.Name) >= 33 and string.len(item.Name) <= 37 then
                        collectibleCount = collectibleCount + 1
                    end
                end
            end

            if totalModelCount > 0 and (collectibleCount / totalModelCount) > 0.8 then
                correctChunkerFolder = folder
                break
            elseif totalModelCount > 0 and collectibleCount > 0 and totalModelCount == collectibleCount then
                correctChunkerFolder = folder
                break
            end
        end
    end

    if not correctChunkerFolder then return end

    for _, collectible in ipairs(correctChunkerFolder:GetChildren()) do
        if collectible:IsA("Model") and string.len(collectible.Name) >= 33 and string.len(collectible.Name) <= 37 then
            pcall(function()
                if Pickup then
                    Pickup:FireServer(collectible.Name)
                    collectible:Destroy()
                else
                    warn("RemoteEvent 'CollectPickup' is nil!")
                end
            end)
            task.wait(0.15)
        end
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
    Remote:FireServer("ClaimSeason")
end

Window:CreateTask(function()
    if toggleStates.autocollectseason then
        collectseasonpass()
    end
end, 0.01)

AimbotSection:AddToggle("Anti AFK", false, function(value)
    toggleStates.antiafk = value
end)

Window:CreateTask(function()
    if toggleStates.antiafk and (os.time() - lastAction >= 60) then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        lastAction = os.time()
    end
end, 3)

local function redeemAllCodes()
    local redeemed = 0
    local failed = 0
    local alreadyRedeemed = 0
    
    -- Get the RemoteFunction reference
    local redeemFunction = game:GetService("ReplicatedStorage"):FindFirstChild("Shared", true)
                          and game:GetService("ReplicatedStorage").Shared:FindFirstChild("Framework", true)
                          and game:GetService("ReplicatedStorage").Shared.Framework:FindFirstChild("Network", true)
                          and game:GetService("ReplicatedStorage").Shared.Framework.Network:FindFirstChild("Remote", true)
                          and game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote:FindFirstChild("Function", true)
    
    if not redeemFunction then
        warn("Could not find redeem function!")
        return
    end
    
    print("\n=== Starting code redemption ===")
    
    for _, code in ipairs(codes) do
        local args = {
            [1] = "RedeemCode",
            [2] = code
        }
        
        local success, result = pcall(function()
            return redeemFunction:InvokeServer(unpack(args))
        end)
        
        if success then
            if result == true then
                print("✅ Successfully redeemed code:", code)
                redeemed = redeemed + 1
            elseif type(result) == "string" and string.find(result:lower(), "already") then
                print("ℹ️ Code already redeemed:", code)
                alreadyRedeemed = alreadyRedeemed + 1
            else
                print("❓ Unexpected response for code:", code, "Response:", result)
                failed = failed + 1
            end
        else
            warn("❌ Failed to redeem code:", code, "Error:", result)
            failed = failed + 1
        end
        
        -- Small delay between redeems to avoid rate limiting
        task.wait(0.5)
    end
    
    print("\n=== Redemption Summary ===")
    print(string.format("Redeemed: %d | Already redeemed: %d | Failed: %d", redeemed, alreadyRedeemed, failed))
    print("Total codes processed:", #codes)
    
    return {
        redeemed = redeemed,
        alreadyRedeemed = alreadyRedeemed,
        failed = failed
    }
end

AimbotSection:AddButton("Redeem All Codes", function()
    local result = redeemAllCodes()
    
    -- Optional: Show a notification with the results
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Code Redemption",
        Text = string.format("Redeemed %d new codes!\n(%d already claimed)", result.redeemed, result.alreadyRedeemed),
        Duration = 5,
    })
end)

-- Enchanting Tab Sections
local TriggerSection = CombatTab:AddSection("Enchanting")

local function ResetEnchant()
    local success, result = pcall(function()
        local inventoryFrame = LP.PlayerGui.ScreenGui.Inventory.Frame
        if not inventoryFrame then return end
        
        local enchant1 = inventoryFrame.Inner.Pets.Details.Enchants["Enchant1"].Title
        local enchant2 = inventoryFrame.Inner.Pets.Details.Enchants["Enchant2"].Title
        enchant1.Text = "NIL"
        enchant2.Text = "NIL"
        return enchant1.Text or enchant2.Text
    end)

    if not success then
        warn("Failed to reset enchant display:", result)
    end
end

TriggerSection:AddToggle("Auto Enchant", false, function(value)
    toggleStates.autoEnchantEnabled = value
    if value then ResetEnchant() end
end)

local function CleanEnchantName(name)
    if type(name) ~= "string" then
        warn("CleanEnchantName received non-string input:", name, type(name))
        return ""
    end
    return name:gsub("[^%w%s]", "")
end

local function TrimWhitespace(str)
    return str:match("^%s*(.-)%s*$")
end

local function GetCurrentEnchants(petUUID)
    local success, result = pcall(function()
        local enchantTitle1 = LP.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant1"].Title
        local enchantTitle2 = LP.PlayerGui.ScreenGui.Inventory.Frame.Inner.Pets.Details.Enchants["Enchant2"].Title
        return {enchantTitle1.Text, enchantTitle2.Text}
    end)

    if not success then
        warn("Failed to get current enchants for pet:", petUUID, result)
        return {}
    end
    return result
end

local function autoEnchantLogic()
    -- Validate pet selection
    if not selectedStates.pet or selectedStates.pet == "" then
        print("No pet selected for enchanting.")
        return false
    end
    
    -- Get desired enchants
    local desiredEnchants = selectedStatesMulti.enchants
    if not desiredEnchants or #desiredEnchants == 0 then
        if selectedStates.enchant and selectedStates.enchant ~= "" then
            desiredEnchants = {selectedStates.enchant}
        else
            print("No desired enchants selected.")
            return false
        end
    end
    
    -- Debug output
    print("\n=== Enchant Debug ===")
    print("Selected pet:", selectedStates.pet)
    print("Desired enchants:", table.concat(desiredEnchants, ", "))
    
    -- Get current enchants (with retry logic)
    local currentEnchants = {}
    for i = 1, 3 do -- Try up to 3 times to get valid enchants
        currentEnchants = GetCurrentEnchants(selectedStates.pet)
        if #currentEnchants > 0 and not (currentEnchants[1] == "NIL" and currentEnchants[2] == "NIL") then
            break
        end
    end
    
    print("Current enchants:")
    for i, enchant in ipairs(currentEnchants) do
        print(string.format("  Slot %d: %s", i, enchant or "NIL"))
    end
    
    -- Check if we need to open pet UI first
    if currentEnchants[1] == "NIL" and currentEnchants[2] == "NIL" then
        print("UI may not be open - attempting to open pet UI...")
        
        -- Try to open the pet UI
        local args = {
            [1] = "SetPetSelected",
            [2] = selectedStates.pet
        }
        Remote:FireServer(unpack(args))
        
        -- Refresh enchant data after opening UI
        currentEnchants = GetCurrentEnchants(selectedStates.pet)
        print("Refreshed enchants after UI open:")
        for i, enchant in ipairs(currentEnchants) do
            print(string.format("  Slot %d: %s", i, enchant or "NIL"))
        end
    end
    
    -- Check for matches
    for _, currentEnchant in ipairs(currentEnchants) do
        if not currentEnchant or currentEnchant == "" or currentEnchant == "NIL" then
            continue
        end
        
        local cleanedCurrent = TrimWhitespace(CleanEnchantName(currentEnchant)):lower()
        
        for _, desiredEnchant in ipairs(desiredEnchants) do
            local cleanedDesired = TrimWhitespace(CleanEnchantName(desiredEnchant)):lower()
            
            print(string.format("Comparing: '%s' vs '%s'", cleanedCurrent, cleanedDesired))
            
            if cleanedCurrent == cleanedDesired then
                print("✓ Match found:", desiredEnchant)
                return false
            end
        end
    end
    
    -- If we get here, no matches were found
    print("No matches found - attempting reroll...")
    
    local args = {
        [1] = "RerollEnchants",
        [2] = selectedStates.pet
    }
    
    -- Call the remote function
    local success, result = pcall(function()
        return game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote.Function:InvokeServer(unpack(args))
    end)
    
    if not success then
        warn("RemoteFunction error:", result)
        return false
    end
    
    print("Reroll attempted - waiting for update...")
    lastRerollTime = os.time()

    local newEnchants = GetCurrentEnchants(selectedStates.pet)
    print("Post-reroll enchants:")
    for i, enchant in ipairs(newEnchants) do
        print(string.format("  Slot %d: %s", i, enchant or "NIL"))
    end
    
    return true
end

Window:CreateTask(function()
    if toggleStates.autoEnchantEnabled then
        local success, result = pcall(autoEnchantLogic)
        if not success then
            warn("Error in auto enchant logic:", result)
        end
    end
end, 0.01)

local enchantOptions = {" Team Up I", "Team Up II", " Team Up III", " Team Up IV", " Team Up V", "  High Roller"}
TriggerSection:AddMultiDropdown("Enchants", enchantOptions, {}, function(selectedEnchants)
    selectedStatesMulti.enchants = selectedEnchants
end)

local function GetEquippedPetNames()
    local petNames = {}
    local success, result = pcall(function()
        local inventoryFrame = LP.PlayerGui:FindFirstChild("ScreenGui")
        if not inventoryFrame then return petNames end
        
        inventoryFrame = inventoryFrame:FindFirstChild("Inventory")
        if not inventoryFrame then return petNames end
        
        inventoryFrame = inventoryFrame:FindFirstChild("Frame")
        if not inventoryFrame or not inventoryFrame.Visible then return petNames end
        
        local inner = inventoryFrame:FindFirstChild("Inner")
        if not inner then return petNames end
        
        local pets = inner:FindFirstChild("Pets")
        if not pets then return petNames end
        
        local main = pets:FindFirstChild("Main")
        if not main then return petNames end
        
        local scrollingFrame = main:FindFirstChild("ScrollingFrame")
        if not scrollingFrame then return petNames end
        
        local team = scrollingFrame:FindFirstChild("Team")
        if not team then return petNames end
        
        local teamMain = team:FindFirstChild("Main")
        if not teamMain then return petNames end
        
        local list = teamMain:FindFirstChild("List")
        if not list then return petNames end
        
        for _, petFrame in ipairs(list:GetChildren()) do
            if petFrame:IsA("Frame") then
                local petName = petFrame.Name:gsub("-team%-?%d*", "")
                table.insert(petNames, petName)
            end
        end
        return petNames
    end)

    if not success then
        warn("Failed to get equipped pets:", result)
        return {"No pets found"}
    end
    
    if #petNames == 0 then
        return {"No pets equipped"}
    end
    
    return petNames
end

local petDropdown
petDropdown = TriggerSection:AddDropdown("Pet (Equipped in order)", GetEquippedPetNames(), "", function(selected)
    selectedStates.pet = selected
end)

TriggerSection:AddButton("Refresh Pets", function()
    local updatedPets = GetEquippedPetNames()
    if petDropdown and petDropdown.Refresh then
        petDropdown:Refresh(updatedPets)
        print("Refreshed pet dropdown with", #updatedPets, "pets")
    else
        warn("Could not refresh pet dropdown - reference not available")
    end
end)

-- Optimize Tab Sections
local OptimizeSection = CombatTab:AddSection("Optimization")

local PlayerGui = LP:WaitForChild("PlayerGui")

local blackScreenGui = Instance.new("ScreenGui")
blackScreenGui.Name = "BlackScreenGui"
blackScreenGui.DisplayOrder = 200
blackScreenGui.Enabled = false
blackScreenGui.Parent = PlayerGui

local blackFrame = Instance.new("Frame")
blackFrame.Name = "BlackFrame"
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.AnchorPoint = Vector2.new(0.5, 0.5)
blackFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
blackFrame.ZIndex = 1
blackFrame.Parent = blackScreenGui

local function GPURenderingToggle(value)
    RunService:Set3dRenderingEnabled(not value)
    blackScreenGui.Enabled = value
end

OptimizeSection:AddToggle("Disable 3D Rendering", false, function(value)
    toggleStates.rendering = value
    GPURenderingToggle(value)
end)

OptimizeSection:AddToggle("Low Graphics Mode", false, function(value)
    toggleStates.lowgp = value
    
    local lighting = game:GetService("Lighting")
    
    if value then
        -- Save current settings
        toggleStates.savedGraphicsQuality = settings().Rendering.QualityLevel
        
        toggleStates.savedLightingProperties = {
            Brightness = lighting.Brightness,
            GlobalShadows = lighting.GlobalShadows,
            Technology = lighting.Technology,
            EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = lighting.EnvironmentSpecularScale
        }
        
        -- Apply low graphics settings
        settings().Rendering.QualityLevel = 1
        lighting.Brightness = lighting.Brightness * 0.8
        lighting.GlobalShadows = false
        lighting.Technology = Enum.Technology.Compatibility
        lighting.EnvironmentDiffuseScale = 0
        lighting.EnvironmentSpecularScale = 0
        
        -- Disable post-processing effects
        for _, effect in ipairs({"Bloom", "Blur", "SunRays", "ColorCorrection", "DepthOfField"}) do
            if lighting:FindFirstChild(effect) then
                toggleStates["saved"..effect] = lighting[effect].Enabled
                lighting[effect].Enabled = false
            end
        end
        
        -- Reduce terrain quality
        if workspace:FindFirstChild("Terrain") then
            local terrain = workspace.Terrain
            toggleStates.savedTerrainProperties = {
                WaterReflectance = terrain.WaterReflectance,
                WaterTransparency = terrain.WaterTransparency,
                WaterWaveSize = terrain.WaterWaveSize,
                WaterWaveSpeed = terrain.WaterWaveSpeed
            }
            
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end
        
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    else
        -- Restore settings
        if toggleStates.savedGraphicsQuality then
            settings().Rendering.QualityLevel = toggleStates.savedGraphicsQuality
        end
        
        if toggleStates.savedLightingProperties then
            for property, value in pairs(toggleStates.savedLightingProperties) do
                pcall(function() lighting[property] = value end)
            end
        end
        
        for _, effect in ipairs({"Bloom", "Blur", "SunRays", "ColorCorrection", "DepthOfField"}) do
            if toggleStates["saved"..effect] ~= nil and lighting:FindFirstChild(effect) then
                lighting[effect].Enabled = toggleStates["saved"..effect]
            end
        end
        
        if toggleStates.savedTerrainProperties and workspace:FindFirstChild("Terrain") then
            local terrain = workspace.Terrain
            for property, value in pairs(toggleStates.savedTerrainProperties) do
                pcall(function() terrain[property] = value end)
            end
        end
        
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end
end)

OptimizeSection:AddToggle("Disable Particles", false, function(value)
    toggleStates.disableparticles = value
    
    -- Store the connection
    if toggleStates.particleConnection then
        table.insert(connections, toggleStates.particleConnection)
        toggleStates.particleConnection:Disconnect()
        toggleStates.particleConnection = nil
    end
    
    local function processParticles(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ParticleEmitter") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Sparkles") then
                child.Enabled = not value
            end
            processParticles(child)
        end
    end
    
    processParticles(workspace)
    
    if value then
        toggleStates.particleConnection = workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or descendant:IsA("Fire") or descendant:IsA("Sparkles") then
                descendant.Enabled = false
            end
        end)
        table.insert(connections, toggleStates.particleConnection)
    end
end)

-- Visuals Tab Sections
local ESPSection = VisualsTab:AddSection("Rift")

ESPSection:AddToggle("Auto Rift", false, function(value)
    toggleStates.autorift = value
end)

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
    if match1 then return tonumber(match1) or 0 end
    
    local match2 = string.match(luckText, "(%d+)x")
    if match2 then return tonumber(match2) or 0 end
    
    local match3 = string.match(luckText, "(%d+)")
    if match3 then return tonumber(match3) or 0 end
    
    return 0
end

local function smoothTeleportTo(targetCFrame)
    local character = LP.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local startPos = rootPart.Position
    local horizontalDistance = (Vector3.new(targetCFrame.X, 0, targetCFrame.Z) -
                              Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
    local verticalDifference = math.abs(targetCFrame.Y - startPos.Y)
    local teleportSpeed = math.clamp(30 + (horizontalDistance / 10), 5, 10)
    
    local tweenInfo = TweenInfo.new(
        horizontalDistance / teleportSpeed,
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
        isAtHatchingLocation = false
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local riftsFolder = workspace:FindFirstChild("Rendered") and workspace.Rendered:FindFirstChild("Rifts")
    local selectedRifts = selectedStatesMulti.rifts or {}
    local selectedLuck = selectedStatesMulti.riftsLuck or {}
    
    local eggToHatch
    if riftsFolder and #selectedRifts > 0 then
        local bestRift, highestLuck = nil, 0
        
        for _, riftName in ipairs(selectedRifts) do
            local rift = riftsFolder:FindFirstChild(riftName)
            if rift then
                local riftLuck = getRiftLuck(rift)
                if riftLuck > 0 then
                    local luckStr = "x"..tostring(riftLuck)
                    if table.find(selectedLuck, luckStr) and riftLuck > highestLuck then
                        highestLuck = riftLuck
                        bestRift = rift
                        eggToHatch = RiftToEggMap[riftName] or riftName:gsub("-rift", " Egg"):gsub("rift", " Egg")
                    end
                end
            end
        end
        
        if bestRift then
            local displayPart = bestRift:FindFirstChild("Display")
            if displayPart then
                smoothTeleportTo(displayPart.CFrame)
                if (rootPart.Position - displayPart.Position).Magnitude < 15 then
                    isAtHatchingLocation = true
                    currentHatchingEgg = eggToHatch
                    Remote:FireServer("HatchEgg", eggToHatch, slider.eggquan)
                    return
                end
            end
        end
    end
    
    local fallbackEggName = selectedStates.fallbackEgg
    if fallbackEggName ~= "" then
        local fallbackEggPosition = EggPositions[fallbackEggName]
        if fallbackEggPosition then
            smoothTeleportTo(CFrame.new(fallbackEggPosition))
            if (rootPart.Position - fallbackEggPosition).Magnitude < 15 then
                isAtHatchingLocation = true
                currentHatchingEgg = fallbackEggName
                Remote:FireServer("HatchEgg", fallbackEggName, slider.eggquan)
                return
            end
        end
    end
    
    isAtHatchingLocation = false
    currentHatchingEgg = nil
end

Window:CreateTask(function()
    if toggleStates.autorift and isAtHatchingLocation and currentHatchingEgg then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.001)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end
end, 0.001)

Window:CreateTask(function()
    if toggleStates.spamrkey then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.001)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end
end, 0.001)

Window:CreateTask(function()
    if toggleStates.stuckpos then
        humanoid.WalkSpeed = 0
        hrp.Anchored = true
    else
        humanoid.WalkSpeed = 30
        hrp.Anchored = false
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

ESPSection:AddToggle("Spam R Key", false, function(value)
    toggleStates.spamrkey = value
end)

ESPSection:AddToggle("Freeze player in place", false, function(value)
    toggleStates.stuckpos = value
end)

-- Misc Tab Sections
local ServerSection = MiscTab:AddSection("Server")
ServerSection:AddButton("Rejoin Server", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

ServerSection:AddButton("Server Hop", function()
    -- Implement server hopping logic here
end)

local SettingsSection = MiscTab:AddSection("Settings")
SettingsSection:AddTextbox("Custom Name", "", "Enter name...", function(text)
    -- Handle custom name logic
end)

SettingsSection:AddToggle("Auto-Execute", false, function(value)
    -- Handle auto-execute logic
end)

local configsect = MiscTab:AddSection("Config Management")
configsect:AddDropdown("Config name", {}, "", function(text)
    -- Handle config selection
end)

configsect:AddButton("Save", function()
    -- Handle config save
end)

configsect:AddButton("Load", function()
    -- Handle config load
end)