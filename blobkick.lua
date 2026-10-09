local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local KICK_OFFSET = Vector3.new(0, 2.5, 0)
local TARGET_REFRESH = 0.5

local targetPlayer = nil
local active = false
local conn = nil
local lastCheck = 0

local function findTarget(name)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name == name and plr ~= LocalPlayer then
            return plr
        end
    end
    return nil
end

local function getTargetRoot()
    if not targetPlayer or not targetPlayer.Character then return nil end
    return targetPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function teleport()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local tRoot = getTargetRoot()
    if not tRoot then return end
    myRoot.CFrame = CFrame.new(tRoot.Position + KICK_OFFSET)
end

local function startKick()
    if active then return end
    active = true
    conn = RunService.Heartbeat:Connect(function()
        if not active then return end
        local now = tick()
        if now - lastCheck > TARGET_REFRESH then
            lastCheck = now
            if targetPlayer and not getTargetRoot() then
                targetPlayer = nil
            end
        end
        if targetPlayer then teleport() end
    end)
end

local function stopKick()
    active = false
    if conn then conn:Disconnect() conn = nil end
end

local function getNames()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.Name) end
    end
    return list
end

local KickTab = Window:AddTab("Blob Kick", "skull")
local Group = KickTab:AddLeftGroupbox("Target")
local dropdown

dropdown = Group:AddDropdown("TargetPlayer", {
    Values = getNames(),
    Default = 1,
    Text = "Select Target",
    Callback = function(v) targetPlayer = findTarget(v) end,
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    dropdown:Refresh(getNames())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    dropdown:Refresh(getNames())
    if targetPlayer and not targetPlayer.Parent then targetPlayer = nil end
end)

Group:AddButton({
    Text = "START KICK",
    Func = function()
        if not targetPlayer then Library:Notify("No target", 3) return end
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if not hum or not hum.Sit then Library:Notify("Sit on Blobman first", 4) return end
        startKick()
        Library:Notify("Kicking: " .. targetPlayer.Name, 3)
    end,
})

Group:AddButton({
    Text = "STOP KICK",
    Func = function()
        stopKick()
        Library:Notify("Stopped", 2)
    end,
})

LocalPlayer.CharacterAdded:Connect(stopKick)