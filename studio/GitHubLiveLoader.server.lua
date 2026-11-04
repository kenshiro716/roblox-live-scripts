-- Publish this bootstrap once. Core GitHub code finishes boot before gated server scripts.
game:GetService("Players").CharacterAutoLoads = false
local Runtime = require(script.Parent:WaitForChild("GitHubRuntime"))
Runtime.Boot()
Runtime.RunExtras()
