-- Server-only bridge. Source bodies are loaded from GitHub; Instances preserve Roblox dependencies.
local Http = game:GetService("HttpService")
local Runtime = {}
local BASE = "https://raw.githubusercontent.com/kenshiro716/roblox-live-scripts/main/"
local sources
local loading = false
local failure
local bootState = "waiting"
local bootError
local environment = getfenv()
local function fetch(path)
    return Http:GetAsync(BASE .. path, true)
end
function Runtime.Load()
    if sources then return end
    if loading then
        repeat task.wait() until not loading
        assert(sources, failure)
        return
    end
    loading = true
    local ok, result = xpcall(function()
        local bundle = Http:JSONDecode(fetch("runtime-bundle.json"))
        assert(bundle.schema == 1 and type(bundle.sources) == "table", "Invalid GitHub bundle")
        local count = 0
        for id, entry in pairs(bundle.sources) do
            assert(type(id) == "string" and type(entry.source) == "string", "Invalid source entry")
            local fn, err = loadstring(entry.source, "GitHub/" .. entry.path)
            assert(fn, err)
            count += 1
        end
        assert(count >= 159, "GitHub bundle is incomplete")
        sources = bundle.sources
        script:SetAttribute("SourceCount", count)
        script:SetAttribute("BundleLoaded", true)
        print("[GitHubRuntime] Loaded and compiled", count, "GitHub server sources")
    end, debug.traceback)
    loading = false
    if not ok then failure = result; error(result, 0) end
end
local function execute(context)
    Runtime.Load()
    local id = context:GetAttribute("GitHubSourceId")
    local entry = sources[id]
    assert(entry, "No GitHub source for " .. context:GetFullName())
    local fn, err = loadstring(entry.source, "GitHub/" .. entry.path)
    assert(fn, err)
    setfenv(fn, setmetatable({script = context}, {__index = environment}))
    return fn()
end
function Runtime.Require(context)
    -- Native require caches each ModuleScript shim; this retains per-clone module behavior.
    return execute(context)
end
function Runtime.WaitReady()
    local deadline = os.clock() + 120
    while bootState == "waiting" or bootState == "booting" do
        assert(os.clock() < deadline, "GitHub startup timed out")
        task.wait()
    end
    assert(bootState == "ready", bootError or "GitHub startup failed")
end
function Runtime.Run(context)
    Runtime.WaitReady()
    return execute(context)
end
function Runtime.Boot()
    assert(bootState == "waiting", "GitHub Boot must only run once")
    bootState = "booting"
    local ok, err = xpcall(function()
        Runtime.Load()
        local templates = game:GetService("ServerStorage"):FindFirstChild("GitHubTemplates")
        assert(templates, "Missing GitHubTemplates; restore the published tool and module templates")
        local installer, compileError = loadstring(fetch("scripts/setup.lua"), "GitHub/scripts/setup.lua")
        assert(installer, compileError)
        installer(templates)
        local storage = game:GetService("ServerStorage")
        assert(storage:FindFirstChild("Server") and storage.Server:FindFirstChild("Boot"), "GitHub setup did not create Server.Boot")
        assert(storage:FindFirstChild("Items"), "GitHub setup did not create Items")
        script:SetAttribute("SetupComplete", true)
        print("[GitHubRuntime] Starting Server.Boot from GitHub")
        require(game:GetService("ServerStorage"):WaitForChild("Server"):WaitForChild("Boot"))()
    end, debug.traceback)
    if not ok then
        bootError = err
        bootState = "failed"
        script:SetAttribute("BootError", tostring(err))
        error(err, 0)
    end
    bootState = "ready"
    script:SetAttribute("BootReady", true)
    print("[GitHubRuntime] Server.Boot complete; releasing remaining server scripts")
end
function Runtime.RunExtras()
    local attempted = {}
    while true do
        local ok, err = xpcall(function()
            local manifest = Http:JSONDecode(fetch("manifest.json"))
            assert(type(manifest.scripts) == "table", "Invalid extra-script manifest")
            for _, entry in ipairs(manifest.scripts) do
                if entry.enabled ~= false then
                    assert(type(entry.path) == "string" and entry.path:match("^scripts/[%w_/%-%.]+%.lua$")
                        and not entry.path:find("..", 1, true), "Invalid extra script path")
                    assert(type(entry.version) == "string" and entry.version ~= "", "Missing script version")
                    if attempted[entry.path] ~= entry.version then
                        local fn, compileError = loadstring(fetch(entry.path), "GitHub/" .. entry.path)
                        assert(fn, compileError)
                        attempted[entry.path] = entry.version
                        local success, message = xpcall(fn, debug.traceback)
                        if success then print("[GitHubRuntime] Extra ran", entry.path, entry.version)
                        else warn("[GitHubRuntime] Extra failed", entry.path, message) end
                    end
                end
            end
        end, debug.traceback)
        if not ok then warn("[GitHubRuntime] Extras:", err) end
        task.wait(60)
    end
end
return Runtime
