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
return true
