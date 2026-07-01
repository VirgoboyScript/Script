-- =============================================================================
-- CONFIG GLOBLAL & UI SETUP
-- =============================================================================
getgenv().customAutoFish = true
getgenv().autoSell = false

local player = game.Players.LocalPlayer
local repStorage = game:GetService("ReplicatedStorage")
local fishingSys = repStorage:WaitForChild("FishingSystem")

-- Remote Events untuk Mancing
local castRemote = fishingSys:WaitForChild("CastReplication")
local claimRemote = fishingSys:WaitForChild("FishGiver")
local cleanRemote = fishingSys:WaitForChild("CleanupCast")
local config = require(fishingSys:WaitForChild("FishingConfig"))
local fakePityTracker = config.CreatePityTracker()

-- Remote Function untuk Jual Iced/Fish
local inventoryEvents = fishingSys:WaitForChild("InventoryEvents", 5)
local sellRemote = inventoryEvents and inventoryEvents:WaitForChild("Inventory_SellAll", 5)

-- Bikin ScreenGui
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "AutoSellProGUI"

-- Bikin Frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.Active = true
frame.Draggable = true

-- Bikin Kolom Input Jeda Waktu Jual
local inputBox = Instance.new("TextBox", frame)
inputBox.Size = UDim2.new(0, 180, 0, 30)
inputBox.Position = UDim2.new(0, 10, 0, 10)
inputBox.PlaceholderText = "Jeda Jual Ikan (Detik)"
inputBox.Text = "30" -- Default diubah ke 30 detik biar lebih aman & ga mengganggu mancing
inputBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextColor3 = Color3.fromRGB(0, 0, 0)
inputBox.Font = Enum.Font.SourceSansBold
inputBox.TextSize = 16

-- Bikin Tombol Toggle Auto Sell
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0, 180, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0, 50)
toggleBtn.Text = "START AUTO SELL"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16

-- Logic Tombol UI
toggleBtn.MouseButton1Click:Connect(function()
    getgenv().autoSell = not getgenv().autoSell
    if getgenv().autoSell then
        toggleBtn.Text = "STOP AUTO SELL"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        toggleBtn.Text = "START AUTO SELL"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
end)

-- =============================================================================
-- LOGIC DETEKSI AREA (OCEAN / LAKE)
-- =============================================================================
local function getArea(position)
    local collectionService = game:GetService("CollectionService")
    local oceanZones = collectionService:GetTagged("OceanZone")
    for _, zone in ipairs(oceanZones) do
        if zone:IsA("BasePart") then
            local localPos = zone.CFrame:PointToObjectSpace(position)
            local halfSize = zone.Size / 2
            if math.abs(localPos.X) <= halfSize.X and math.abs(localPos.Y) <= halfSize.Y and math.abs(localPos.Z) <= halfSize.Z then
                return "ocean"
            end
        end
    end
    return "lake"
end

-- =============================================================================
-- THREAD 1: LOOPING UTAMA AUTO FISH
-- =============================================================================
task.spawn(function()
    while getgenv().customAutoFish do
        local character = player.Character
        local equippedRod = character and character:FindFirstChildOfClass("Tool")
        
        if not equippedRod or not equippedRod:FindFirstChild("Part") then
            warn("âš ï¸ Pegang pancinganmu dulu bos!")
            task.wait(2)
            continue
        end
        
        local rodName = equippedRod.Name
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local lookVector = rootPart and rootPart.CFrame.LookVector or Vector3.new(0, 0, -1)
        
        local hookPos = equippedRod.Part.Position + (lookVector * 15)
        local velocity = Vector3.new(0, 10, 0)
        local power = 100
        local currentArea = getArea(hookPos)
        
        -- Lempar Pancingan
        castRemote:FireServer(hookPos, velocity, rodName, power)
        
        -- Jeda Umpan Dimakan (Meniru game asli)
        local safeWait = math.random(35, 50) / 10
        task.wait(safeWait)
        
        -- Kalkulasi & Roll Ikan via Modul Internal Game
        local rodConfig = config.GetRodConfig(rodName)
        local totalLuck = config.CalculateTotalLuck(rodConfig.baseLuck, 1)
        local fishData = config.RollFish(fakePityTracker, rodName, totalLuck, currentArea)
        
        if fishData then
            local fishWeight = config.GenerateFishWeight(fishData, totalLuck, rodConfig.maxWeight)
            
            -- Kirim data klaim
            claimRemote:FireServer({
                ["name"] = fishData.name,
                ["weight"] = fishWeight,
                ["rarity"] = fishData.rarity,
                ["hookPosition"] = hookPos,
                ["area"] = currentArea
            })
            print("ðŸŸ Dapat: " .. fishData.name .. " | Bobot: " .. string.format("%.2f", fishWeight) .. " kg")
        end
        
        -- Tarik & Bersihkan Pancingan
        cleanRemote:FireServer()
        
        -- Jeda antar lemparan pancing
        task.wait(1)
    end
end)

-- =============================================================================
-- THREAD 2: LOOPING AUTO SELL INDEPENDEN
-- =============================================================================
task.spawn(function()
    while true do
        local waitTime = tonumber(inputBox.Text) or 30
        task.wait(waitTime)
        
        if getgenv().autoSell and sellRemote then
            print("ðŸ’° Menjual semua ikan di inventory...")
            local success, err = pcall(function()
                sellRemote:InvokeServer()
            end)
            if success then
                print("âœ… Sukses menjual ikan!")
            else
                warn("âŒ Gagal menjual ikan:", err)
            end
        end
    end
end)
