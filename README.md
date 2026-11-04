# Roblox live scripts

Server code exported from Prime Fruits. The initial migration contains 37 Server ModuleScripts, 63 item server Scripts, 59 item ModuleScripts, and 63 client LocalScripts.

## Startup
The installed GitHubLiveLoader loads and syntax-checks the 159 server source entries before invoking Server.Boot. Other server scripts are gated until Boot completes. Tools, remotes, folders, client scripts, and shared client data remain in the place because Roblox needs those Instances. Server source bodies are replaced with small GitHub bridge shims.

Item scripts run when their tool scripts normally run, rather than all tools executing at server startup. ModuleScripts retain normal lazy require and per-instance caching.

## Edit existing server code
Edit its file under sources/Server or sources/Items. The Build Roblox server bundle action regenerates runtime-bundle.json. Wait for that action to finish, then start a new Roblox server. Core modules are cached for a server's lifetime and are not hot-reloaded.

The LocalScripts under sources/Items are backups. Client code and the client branch of shared ModuleScripts still require Studio publishing when edited; server loadstring cannot execute on clients.

## Add extra live server scripts
Add a .lua file under scripts/, then add its path, a string version, and enabled=true to manifest.json. Extras run sequentially after core Boot and are checked every 60 seconds. Increment version to execute a change in existing servers. Scripts should finish initialization and spawn long-running loops using task.spawn. Removing an entry does not undo its effects.

## First deployment
Enable Allow HTTP Requests and ServerScriptService.LoadStringEnabled. Test in Studio, then publish the place once. Future GitHub server-code updates are loaded by new servers without republishing the place.

GitHub code has full server privileges. Never put tokens or credentials in this public repository.

## Recovery
A full original source export is saved locally as migration-backup.json. The initial migration preserves all tool assets and dependency Instances.
