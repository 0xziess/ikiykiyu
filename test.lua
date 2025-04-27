local UILibrary = {}

-- Configuration
local config = {
    fontFamily = "Code", -- Gothic-like font
    mainColor = Color3.fromRGB(25, 25, 25),
    accentColor = Color3.fromRGB(120, 48, 43), -- Dark red for gothic theme
    textColor = Color3.fromRGB(255, 255, 255),
    secondaryColor = Color3.fromRGB(35, 35, 35),
    cornerRadius = UDim.new(0, 4),
    elementHeight = 35,
    padding = 10
}

-- Create the main UI container
function UILibrary:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ExploitUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Parent the ScreenGui appropriately based on environment
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = game:GetService("CoreGui")
    end
    
    -- Main frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainFrame.BackgroundColor3 = config.mainColor
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    -- MainFrame.Draggable = true -- Removed for custom dragging
    MainFrame.Parent = ScreenGui
    
    -- Setup improved dragging system
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        -- Create a smooth tween for the position change
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local tween = TweenService:Create(MainFrame, tweenInfo, {Position = targetPosition})
        tween:Play()
    end
    
    -- Apply corner radius
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = config.cornerRadius
    UICorner.Parent = MainFrame
    
    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = config.accentColor
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    -- Connect dragging to title bar
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            -- Capture the input and stop it from propagating
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    -- Update drag when mouse moves
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    -- Connect the drag update to RunService for smoother movement
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            updateDrag(dragInput)
        end
    end)
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = config.cornerRadius
    TitleCorner.Parent = TitleBar
    
    -- Title text
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "Title"
    TitleText.Size = UDim2.new(1, -40, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = title or "Gothic Exploit Menu"
    TitleText.TextColor3 = config.textColor
    TitleText.Font = Enum.Font[config.fontFamily]
    TitleText.TextSize = 18
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = config.textColor
    CloseButton.Font = Enum.Font[config.fontFamily]
    CloseButton.TextSize = 18
    CloseButton.Parent = TitleBar
    
    -- Tab container (left side)
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 120, 1, -30)
    TabContainer.Position = UDim2.new(0, 0, 0, 30)
    TabContainer.BackgroundColor3 = config.secondaryColor
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    -- Tab list layout
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 2)
    TabListLayout.Parent = TabContainer
    
    -- Content frame (right side)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -120, 1, -30)
    ContentFrame.Position = UDim2.new(0, 120, 0, 30)
    ContentFrame.BackgroundColor3 = config.mainColor
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    
    -- Tab pages container
    local TabPagesContainer = Instance.new("Frame")
    TabPagesContainer.Name = "TabPagesContainer"
    TabPagesContainer.Size = UDim2.new(1, 0, 1, 0)
    TabPagesContainer.BackgroundTransparency = 1
    TabPagesContainer.Parent = ContentFrame
    
    -- Define the Window object
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        GUI = ScreenGui -- Store reference to ScreenGui for unloading
    }

    -- Add the Unload function
    function Window:Unload()
        if self.GUI and self.GUI.Parent then
            self.GUI:Destroy()
        end
    end

    -- Connect the CloseButton event
    CloseButton.MouseButton1Click:Connect(function()
        Window:Unload()
    end)
    
    -- Add a tab to the window
    function Window:AddTab(tabName)
        local tabIndex = #self.Tabs + 1
        
        -- Create tab button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "Button"
        TabButton.Size = UDim2.new(1, 0, 0, 40)
        TabButton.BackgroundColor3 = config.secondaryColor
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = config.textColor
        TabButton.Font = Enum.Font[config.fontFamily]
        TabButton.TextSize = 16
        TabButton.Parent = TabContainer
        TabButton.LayoutOrder = tabIndex
        
        -- Create tab page
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = tabName .. "Page"
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 4
        TabPage.ScrollBarImageColor3 = config.accentColor
        TabPage.Visible = false
        TabPage.Parent = TabPagesContainer
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        -- Tab page layout
        local TabPageLayout = Instance.new("UIListLayout")
        TabPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabPageLayout.Padding = UDim.new(0, 10)
        TabPageLayout.Parent = TabPage
        
        -- Tab object
        local Tab = {}
        Tab.Name = tabName
        Tab.Button = TabButton
        Tab.Page = TabPage
        Tab.Sections = {}
        
        -- Tab button click handler
        TabButton.MouseButton1Click:Connect(function()
            -- Deactivate current tab
            if Window.ActiveTab then
                Window.ActiveTab.Button.BackgroundColor3 = config.secondaryColor
                Window.ActiveTab.Page.Visible = false
            end
            
            -- Activate this tab
            TabButton.BackgroundColor3 = config.accentColor
            TabPage.Visible = true
            Window.ActiveTab = Tab
        end)
        
        -- Add a section to the tab
        function Tab:AddSection(sectionName)
            local Section = {}
            
            -- Create section container
            local SectionContainer = Instance.new("Frame")
            SectionContainer.Name = sectionName .. "Section"
            SectionContainer.Size = UDim2.new(1, 0, 0, 40) -- Will be auto-sized
            SectionContainer.BackgroundColor3 = config.secondaryColor
            SectionContainer.BorderSizePixel = 0
            SectionContainer.AutomaticSize = Enum.AutomaticSize.Y
            SectionContainer.Parent = TabPage
            
            -- Section corner
            local SectionCorner = Instance.new("UICorner")
            SectionCorner.CornerRadius = config.cornerRadius
            SectionCorner.Parent = SectionContainer
            
            -- Section title
            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Name = "Title"
            SectionTitle.Size = UDim2.new(1, -20, 0, 30)
            SectionTitle.Position = UDim2.new(0, 10, 0, 5)
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Text = sectionName
            SectionTitle.TextColor3 = config.accentColor
            SectionTitle.Font = Enum.Font[config.fontFamily]
            SectionTitle.TextSize = 18
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            SectionTitle.Parent = SectionContainer
            
            -- Section content
            local SectionContent = Instance.new("Frame")
            SectionContent.Name = "Content"
            SectionContent.Size = UDim2.new(1, -20, 0, 0)
            SectionContent.Position = UDim2.new(0, 10, 0, 35)
            SectionContent.BackgroundTransparency = 1
            SectionContent.AutomaticSize = Enum.AutomaticSize.Y
            SectionContent.Parent = SectionContainer

            local SectionPadding = Instance.new("UIPadding")
SectionPadding.PaddingTop = UDim.new(0, 0)
SectionPadding.PaddingLeft = UDim.new(0, 0)
SectionPadding.PaddingRight = UDim.new(0, 0)
SectionPadding.PaddingBottom = UDim.new(0, 10) -- This creates the gap at the bottom
SectionPadding.Parent = SectionContent
            
            -- Section content layout
            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Padding = UDim.new(0, 8)
            SectionLayout.Parent = SectionContent
            
            -- Add button to the section
            function Section:AddButton(buttonText, callback)
                local Button = Instance.new("TextButton")
                Button.Name = buttonText .. "Button"
                Button.Size = UDim2.new(1, 0, 0, config.elementHeight)
                Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                Button.BorderSizePixel = 0
                Button.Text = buttonText
                Button.TextColor3 = config.textColor
                Button.Font = Enum.Font[config.fontFamily]
                Button.TextSize = 16
                Button.Parent = SectionContent
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Parent = Button
                
                -- Simple hover effect
                Button.MouseEnter:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end)
                
                Button.MouseLeave:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                end)
                
                Button.MouseButton1Click:Connect(function()
                    callback()
                end)
                
                return Button
            end
            
            -- Add toggle to the section
            function Section:AddToggle(toggleText, default, callback)
                local ToggleContainer = Instance.new("Frame")
                ToggleContainer.Name = toggleText .. "Toggle"
                ToggleContainer.Size = UDim2.new(1, 0, 0, config.elementHeight)
                ToggleContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                ToggleContainer.BorderSizePixel = 0
                ToggleContainer.Parent = SectionContent
                
                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(0, 4)
                ToggleCorner.Parent = ToggleContainer
                
                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Name = "Label"
                ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
                ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Text = toggleText
                ToggleLabel.TextColor3 = config.textColor
                ToggleLabel.Font = Enum.Font[config.fontFamily]
                ToggleLabel.TextSize = 16
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleContainer
                
                local ToggleButton = Instance.new("Frame")
                ToggleButton.Name = "ToggleButton"
                ToggleButton.Size = UDim2.new(0, 40, 0, 20)
                ToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
                ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Parent = ToggleContainer
                
                local ToggleButtonCorner = Instance.new("UICorner")
                ToggleButtonCorner.CornerRadius = UDim.new(0, 10)
                ToggleButtonCorner.Parent = ToggleButton
                
                local ToggleCircle = Instance.new("Frame")
                ToggleCircle.Name = "Circle"
                ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
                ToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
                ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ToggleCircle.BorderSizePixel = 0
                ToggleCircle.Parent = ToggleButton
                
                local ToggleCircleCorner = Instance.new("UICorner")
                ToggleCircleCorner.CornerRadius = UDim.new(1, 0)
                ToggleCircleCorner.Parent = ToggleCircle
                
                local toggled = default or false
                
                local function updateToggle()
                    if toggled then
                        ToggleButton.BackgroundColor3 = config.accentColor
                        ToggleCircle:TweenPosition(UDim2.new(0, 22, 0.5, -8), "Out", "Sine", 0.1, true)
                    else
                        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        ToggleCircle:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Sine", 0.1, true)
                    end
                    callback(toggled)
                end
                
                -- Set initial state
                updateToggle()
                
                ToggleContainer.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggled = not toggled
                        updateToggle()
                    end
                end)
                
                return ToggleContainer
            end
            
            -- Add slider to the section
            function Section:AddSlider(sliderText, min, max, default, callback)
                local SliderContainer = Instance.new("Frame")
                SliderContainer.Name = sliderText .. "Slider"
                SliderContainer.Size = UDim2.new(1, 0, 0, config.elementHeight * 1.5)
                SliderContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                SliderContainer.BorderSizePixel = 0
                SliderContainer.Parent = SectionContent
                
                local SliderCorner = Instance.new("UICorner")
                SliderCorner.CornerRadius = UDim.new(0, 4)
                SliderCorner.Parent = SliderContainer
                
                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Name = "Label"
                SliderLabel.Size = UDim2.new(1, -70, 0, 20)
                SliderLabel.Position = UDim2.new(0, 10, 0, 5)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = sliderText
                SliderLabel.TextColor3 = config.textColor
                SliderLabel.Font = Enum.Font[config.fontFamily]
                SliderLabel.TextSize = 16
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderContainer
                
                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Name = "Value"
                ValueLabel.Size = UDim2.new(0, 60, 0, 20)
                ValueLabel.Position = UDim2.new(1, -70, 0, 5)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(default)
                ValueLabel.TextColor3 = config.textColor
                ValueLabel.Font = Enum.Font[config.fontFamily]
                ValueLabel.TextSize = 16
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.Parent = SliderContainer
                
                local SliderBackground = Instance.new("Frame")
                SliderBackground.Name = "Background"
                SliderBackground.Size = UDim2.new(1, -20, 0, 10)
                SliderBackground.Position = UDim2.new(0, 10, 0, 30)
                SliderBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                SliderBackground.BorderSizePixel = 0
                SliderBackground.Parent = SliderContainer
                
                local SliderBackgroundCorner = Instance.new("UICorner")
                SliderBackgroundCorner.CornerRadius = UDim.new(0, 5)
                SliderBackgroundCorner.Parent = SliderBackground
                
                local SliderFill = Instance.new("Frame")
                SliderFill.Name = "Fill"
                SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                SliderFill.BackgroundColor3 = config.accentColor
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBackground
                
                local SliderFillCorner = Instance.new("UICorner")
                SliderFillCorner.CornerRadius = UDim.new(0, 5)
                SliderFillCorner.Parent = SliderFill
                
                local value = default
                
                local function updateSlider()
                    SliderFill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
                    ValueLabel.Text = tostring(math.floor(value))
                    callback(value)
                end
                
                SliderBackground.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local connection
                        connection = game:GetService("RunService").RenderStepped:Connect(function()
                            local mouse = game:GetService("Players").LocalPlayer:GetMouse()
                            local percent = math.clamp((mouse.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X, 0, 1)
                            value = min + (max - min) * percent
                            updateSlider()
                        end)
                        
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                connection:Disconnect()
                            end
                        end)
                    end
                end)
                
                -- Set initial value
                updateSlider()
                
                return SliderContainer
            end
            
            -- Add dropdown to the section
            function Section:AddDropdown(dropdownText, options, default, callback)
                local DropdownContainer = Instance.new("Frame")
                DropdownContainer.Name = dropdownText .. "Dropdown"
                DropdownContainer.Size = UDim2.new(1, 0, 0, config.elementHeight)
                DropdownContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                DropdownContainer.BorderSizePixel = 0
                DropdownContainer.ClipsDescendants = true
                DropdownContainer.Parent = SectionContent
                
                local DropdownCorner = Instance.new("UICorner")
                DropdownCorner.CornerRadius = UDim.new(0, 4)
                DropdownCorner.Parent = DropdownContainer
                
                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Name = "Label"
                DropdownLabel.Size = UDim2.new(1, -20, 0, config.elementHeight)
                DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Text = dropdownText
                DropdownLabel.TextColor3 = config.textColor
                DropdownLabel.Font = Enum.Font[config.fontFamily]
                DropdownLabel.TextSize = 16
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = DropdownContainer
                
                local SelectedLabel = Instance.new("TextLabel")
                 SelectedLabel.Name = "Selected"
                 SelectedLabel.Size = UDim2.new(0, 100, 0, config.elementHeight)
                 SelectedLabel.Position = UDim2.new(0, -110, 0, 0)
                 SelectedLabel.BackgroundTransparency = 1
                 SelectedLabel.Text = default or options[1] or "Select"
                 SelectedLabel.TextColor3 = config.accentColor
                 SelectedLabel.Font = Enum.Font[config.fontFamily]
                 SelectedLabel.TextSize = 16
                 SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
                 SelectedLabel.Parent = DropdownContainer
                
                local DropdownArrow = Instance.new("TextLabel")
                DropdownArrow.Name = "Arrow"
                DropdownArrow.Size = UDim2.new(0, 20, 0, 20)
                DropdownArrow.Position = UDim2.new(1, -25, 0, 8)
                DropdownArrow.BackgroundTransparency = 1
                DropdownArrow.Text = "▼"
                DropdownArrow.TextColor3 = config.textColor
                DropdownArrow.Font = Enum.Font[config.fontFamily]
                DropdownArrow.TextSize = 14
                DropdownArrow.Parent = DropdownContainer
                
                local OptionContainer = Instance.new("Frame")
                OptionContainer.Name = "Options"
                OptionContainer.Size = UDim2.new(1, 0, 0, 0)
                OptionContainer.Position = UDim2.new(0, 0, 0, config.elementHeight)
                OptionContainer.BackgroundTransparency = 1
                OptionContainer.ClipsDescendants = true
                OptionContainer.Parent = DropdownContainer
                
                local OptionLayout = Instance.new("UIListLayout")
                OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptionLayout.Parent = OptionContainer
                
                local isOpen = false
                local selected = default or options[1] or "Select"
                
                -- Create option buttons
                for i, option in ipairs(options) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Name = option
                    OptionButton.Size = UDim2.new(1, 0, 0, 30)
                    OptionButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Text = option
                    OptionButton.TextColor3 = config.textColor
                    OptionButton.Font = Enum.Font[config.fontFamily]
                    OptionButton.TextSize = 14
                    OptionButton.Parent = OptionContainer
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        selected = option
                        SelectedLabel.Text = selected
                        isOpen = false
                        DropdownContainer:TweenSize(UDim2.new(1, 0, 0, config.elementHeight), "Out", "Quad", 0.2, true)
                        DropdownArrow.Text = "▼"
                        callback(selected)
                    end)
                    
                    OptionButton.MouseEnter:Connect(function()
                        OptionButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        OptionButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
                    end)
                end
                
                -- Toggle dropdown
                DropdownContainer.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isOpen = not isOpen
                        
                        if isOpen then
                            DropdownContainer:TweenSize(UDim2.new(1, 0, 0, config.elementHeight + (#options * 30)), "Out", "Quad", 0.2, true)
                            DropdownArrow.Text = "▲"
                        else
                            DropdownContainer:TweenSize(UDim2.new(1, 0, 0, config.elementHeight), "Out", "Quad", 0.2, true)
                            DropdownArrow.Text = "▼"
                        end
                    end
                end)
                
                -- Set initial value
                callback(selected)
                
                return DropdownContainer
            end
            
            -- Add text input to the section
            function Section:AddTextbox(boxText, defaultText, placeholder, callback)
                local TextboxContainer = Instance.new("Frame")
                TextboxContainer.Name = boxText .. "Textbox"
                TextboxContainer.Size = UDim2.new(1, 0, 0, config.elementHeight)
                TextboxContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                TextboxContainer.BorderSizePixel = 0
                TextboxContainer.Parent = SectionContent
                
                local TextboxCorner = Instance.new("UICorner")
                TextboxCorner.CornerRadius = UDim.new(0, 4)
                TextboxCorner.Parent = TextboxContainer
                
                local TextboxLabel = Instance.new("TextLabel")
                TextboxLabel.Name = "Label"
                TextboxLabel.Size = UDim2.new(0.4, 0, 1, 0)
                TextboxLabel.Position = UDim2.new(0, 10, 0, 0)
                TextboxLabel.BackgroundTransparency = 1
                TextboxLabel.Text = boxText
                TextboxLabel.TextColor3 = config.textColor
                TextboxLabel.Font = Enum.Font[config.fontFamily]
                TextboxLabel.TextSize = 16
                TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextboxLabel.Parent = TextboxContainer
                
                local Textbox = Instance.new("TextBox")
                Textbox.Name = "Input"
                Textbox.Size = UDim2.new(0.6, -20, 0, 25)
                Textbox.Position = UDim2.new(0.4, 5, 0.5, -12.5)
                Textbox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                Textbox.BorderSizePixel = 0
                Textbox.Text = defaultText or ""
                Textbox.PlaceholderText = placeholder or "Enter text..."
                Textbox.TextColor3 = config.textColor
                Textbox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
                Textbox.Font = Enum.Font[config.fontFamily]
                Textbox.TextSize = 14
                Textbox.Parent = TextboxContainer
                
                local TextboxInputCorner = Instance.new("UICorner")
                TextboxInputCorner.CornerRadius = UDim.new(0, 4)
                TextboxInputCorner.Parent = Textbox
                
                Textbox.FocusLost:Connect(function(enterPressed)
                    callback(Textbox.Text, enterPressed)
                end)
                
                return TextboxContainer
            end
            
            return Section
        end
        
        -- Store tab in window
        table.insert(self.Tabs, Tab)
        
        -- Activate first tab by default
        if #self.Tabs == 1 then
            TabButton.BackgroundColor3 = config.accentColor
            TabPage.Visible = true
            Window.ActiveTab = Tab
        end
        
        return Tab
    end
    
    return Window
end

return UILibrary
