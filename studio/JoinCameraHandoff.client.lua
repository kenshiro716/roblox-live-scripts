-- Hand the menu camera back to Roblox when the server finishes spawning a character.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local function followCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 20)
    local root = character:WaitForChild("HumanoidRootPart", 20)
    if not humanoid or not root then return end
    local deadline = os.clock() + 20
    repeat task.wait() until character:IsDescendantOf(workspace) or os.clock() >= deadline
    if player.Character ~= character or not character:IsDescendantOf(workspace) then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    camera.CameraSubject = humanoid
    camera.CameraType = Enum.CameraType.Custom
    camera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 6, 12), root.Position + Vector3.new(0, 2, 0))
    camera.Focus = root.CFrame
end
player.CharacterAdded:Connect(function(character) task.spawn(followCharacter, character) end)
if player.Character then task.spawn(followCharacter, player.Character) end
