-- TRO FLING PRO - Safe GUI Merge
-- GUI inspired by raw (60). This build keeps player selection and interface controls,
-- but intentionally does not execute fling/knockback, character-joint destruction,
-- or other disruptive actions against other players.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("TRO_FlingPro")
if old then
    old:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TRO_FlingPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local Main = make("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 430, 0, 470),
    Position = UDim2.new(0.5, -215, 0.5, -235),
    BackgroundColor3 = Color3.fromRGB(13, 13, 18),
    BorderSizePixel = 0,
    Active = true,
}, ScreenGui)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, Main)
make("UIStroke", {Color = Color3.fromRGB(105, 65, 190), Thickness = 1.5, Transparency = 0.15}, Main)

local Header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = Color3.fromRGB(25, 20, 37),
    BorderSizePixel = 0,
}, Main)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, Header)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Header.BackgroundColor3,
    BorderSizePixel = 0,
}, Header)

make("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -90, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text = "TRO  •  FLING PRO",
    TextColor3 = Color3.fromRGB(225, 210, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local Close = make("TextButton", {
    Name = "Close",
    Size = UDim2.new(0, 32, 0, 30),
    Position = UDim2.new(1, -42, 0, 11),
    BackgroundColor3 = Color3.fromRGB(105, 42, 62),
    Text = "×",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    BorderSizePixel = 0,
}, Header)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, Close)
Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dragging
do
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

make("TextLabel", {
    Size = UDim2.new(1, -28, 0, 24),
    Position = UDim2.new(0, 14, 0, 62),
    BackgroundTransparency = 1,
    Text = "PLAYER TARGET",
    TextColor3 = Color3.fromRGB(180, 150, 235),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)

local SelectedLabel = make("TextLabel", {
    Name = "SelectedPlayer",
    Size = UDim2.new(1, -28, 0, 32),
    Position = UDim2.new(0, 14, 0, 88),
    BackgroundColor3 = Color3.fromRGB(25, 25, 34),
    BorderSizePixel = 0,
    Text = "Selected: none",
    TextColor3 = Color3.fromRGB(240, 240, 245),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, SelectedLabel)
make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, SelectedLabel)

local Refresh = make("TextButton", {
    Name = "RefreshPlayers",
    Size = UDim2.new(0.5, -18, 0, 32),
    Position = UDim2.new(0, 14, 0, 130),
    BackgroundColor3 = Color3.fromRGB(75, 47, 125),
    BorderSizePixel = 0,
    Text = "Refresh Players",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
}, Main)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, Refresh)

local Nearest = make("TextButton", {
    Name = "NearestPlayer",
    Size = UDim2.new(0.5, -18, 0, 32),
    Position = UDim2.new(0.5, 4, 0, 130),
    BackgroundColor3 = Color3.fromRGB(45, 75, 105),
    BorderSizePixel = 0,
    Text = "Select Nearest",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
}, Main)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, Nearest)

local List = make("ScrollingFrame", {
    Name = "PlayerList",
    Size = UDim2.new(1, -28, 0, 170),
    Position = UDim2.new(0, 14, 0, 172),
    BackgroundColor3 = Color3.fromRGB(19, 19, 26),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, List)
make("UIPadding", {
    PaddingTop = UDim.new(0, 7),
    PaddingBottom = UDim.new(0, 7),
    PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7),
}, List)
local ListLayout = make("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.Name,
}, List)

local Status = make("TextLabel", {
    Name = "Status",
    Size = UDim2.new(1, -28, 0, 34),
    Position = UDim2.new(0, 14, 0, 352),
    BackgroundColor3 = Color3.fromRGB(25, 25, 34),
    BorderSizePixel = 0,
    Text = "Status: Ready",
    TextColor3 = Color3.fromRGB(145, 230, 175),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, Status)
make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, Status)

local SafeNotice = make("TextLabel", {
    Name = "SafeNotice",
    Size = UDim2.new(1, -28, 0, 60),
    Position = UDim2.new(0, 14, 0, 395),
    BackgroundTransparency = 1,
    Text = "Target selection GUI only. Fling/knockback actions are disabled in this build.",
    TextColor3 = Color3.fromRGB(170, 165, 185),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
}, Main)

local selectedPlayer
local function setStatus(message, color)
    Status.Text = "Status: " .. message
    Status.TextColor3 = color or Color3.fromRGB(145, 230, 175)
end

local function selectPlayer(player)
    selectedPlayer = player
    SelectedLabel.Text = "Selected: " .. player.Name
    setStatus("Selected " .. player.Name)
end

local function refreshPlayers()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            count += 1
            local button = make("TextButton", {
                Name = player.Name,
                Size = UDim2.new(1, -2, 0, 30),
                BackgroundColor3 = Color3.fromRGB(35, 31, 47),
                BorderSizePixel = 0,
                Text = player.DisplayName .. "  (@" .. player.Name .. ")",
                TextColor3 = Color3.fromRGB(230, 225, 240),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = count,
            }, List)
            make("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
            make("UIPadding", {PaddingLeft = UDim.new(0, 9)}, button)
            button.MouseButton1Click:Connect(function()
                selectPlayer(player)
            end)
        end
    end

    if count == 0 then
        setStatus("No other players found", Color3.fromRGB(235, 190, 120))
    else
        setStatus(count .. " players listed")
    end
end

local function getRoot(player)
    local character = player and player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

Refresh.MouseButton1Click:Connect(refreshPlayers)
Nearest.MouseButton1Click:Connect(function()
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then
        setStatus("Your character is not ready", Color3.fromRGB(235, 190, 120))
        return
    end

    local nearest, nearestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local root = getRoot(player)
            if root then
                local distance = (root.Position - myRoot.Position).Magnitude
                if not nearestDistance or distance < nearestDistance then
                    nearest, nearestDistance = player, distance
                end
            end
        end
    end

    if nearest then
        selectPlayer(nearest)
        setStatus("Nearest: " .. nearest.Name .. " (" .. math.floor(nearestDistance) .. " studs)")
    else
        setStatus("No nearby players available", Color3.fromRGB(235, 190, 120))
    end
end)

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(player)
    if selectedPlayer == player then
        selectedPlayer = nil
        SelectedLabel.Text = "Selected: none"
        setStatus("Selected player left", Color3.fromRGB(235, 190, 120))
    end
    refreshPlayers()
end)

refreshPlayers()
