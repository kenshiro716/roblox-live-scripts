-- Runs from GitHub before Server.Boot. Rebuild the live folders from published templates.
local templates = ...
assert(typeof(templates) == "Instance", "Missing published GitHubTemplates")
local storage = game:GetService("ServerStorage")
for _, name in ipairs({"Server", "Items"}) do
    assert(not storage:FindFirstChild(name), "Live folder already exists: " .. name)
    local template = assert(templates:FindFirstChild(name), "Missing template: " .. name)
    local copy = template:Clone()
    assert(copy, "Template is not Archivable: " .. name)
    copy.Name = name
    copy.Parent = storage
    print("[GitHub setup] Created ServerStorage." .. name, #copy:GetDescendants(), "objects")
end
-- Repair stock copies as well as the canonical item templates.
local items=storage.Items
local control=items:FindFirstChild("Control-Control")
if control then
    control.ToolTip="Blox Fruit"
    control.RequiresHandle=false
    control:SetAttribute("MovesetV2",true)
    control:SetAttribute("WeaponType","Demon Fruit")
    control:SetAttribute("ControlMode","Base")
    control:SetAttribute("EffectReferences","ControlRework.Domain##ControlRework.DomainCharge##ControlRework.M1.Dagger_Outside##ControlRework.M1.Dagger_Inside##ControlRework.M1.Fist_Inside##ControlRework.X_Outside##ControlRework.NewDaggerX##ControlRework.XFist##ControlRework.C_Outside##ControlRework.CDagger##ControlRework.CFist##ControlRework.F##ControlRework.V_Normal##ControlRework.V_Cutscene##ControlRework.ObjectExplosion")
    control:SetAttribute("FolderReferences","ControlRework")
end
local function repair(tool)
    local canonical=items:FindFirstChild(tool.Name)
    if not canonical or tool==canonical then return end
    if tool.Name~="Triple Dark Blade" and tool.Name~="Control-Control" then return end
    for _,c in ipairs(tool:GetChildren()) do
        if c.ClassName=="Script" then c.Enabled=false; c:Destroy() end
    end
    for _,c in ipairs(canonical:GetChildren()) do
        if c.ClassName=="Script" then c:Clone().Parent=tool end
    end
    local oldData=tool:FindFirstChild("Data")
    if oldData then oldData:Destroy() end
    canonical.Data:Clone().Parent=tool
    tool.ToolTip=canonical.ToolTip
    tool.RequiresHandle=false
    for key,value in pairs(canonical:GetAttributes()) do
        if key~="OwnerId" and key~="Level" and key~="Exp" then tool:SetAttribute(key,value) end
    end
end
for _,tool in ipairs(game:GetService("StarterPack"):GetChildren()) do if tool:IsA("Tool") then repair(tool) end end
for _,player in ipairs(game:GetService("Players"):GetPlayers()) do
    for _,container in ipairs({player:FindFirstChildOfClass("Backpack"),player.Character}) do
        if container then for _,tool in ipairs(container:GetChildren()) do if tool:IsA("Tool") then repair(tool) end end end
    end
end
return true
