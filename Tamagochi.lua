local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

while true do
    task.wait(0.2)

    local characterName = player.Name .. "_Character"
    local targetCharacter = workspace:FindFirstChild("Ignore") and workspace.Ignore:FindFirstChild(characterName)
    local shipFolder = workspace:FindFirstChild("ShipParts")

    if targetCharacter and shipFolder then
        local characterRoot = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")

        if characterRoot then
            local destination = characterRoot.CFrame

            for _, model in pairs(shipFolder:GetChildren()) do
                local hitPart = model:FindFirstChild("HitPart")
                
                if hitPart and hitPart:IsA("BasePart") then
                    hitPart.CFrame = destination
                end
            end
        end
    end
end
