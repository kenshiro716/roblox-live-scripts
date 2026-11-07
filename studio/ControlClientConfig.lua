local movesetkit = require(game:GetService("ReplicatedStorage"):WaitForChild("movesetkit"))
local config={holdkeys={Z=true,X=true,C=true,V=true,F=true},maxhold=3}
function config.noroot(ctx,key) return key=="Z" end
function config.anims(ctx,key)
    local animator=movesetkit.characteranimator(ctx)
    local mode=ctx.tool:GetAttribute("ControlMode")
    if key=="Z" then return {animator=animator,start="CRRoomOpeningStart",loop="CRRoomOpeningLoop",release="CRRoomOpeningEnd"} end
    if key=="F" then return {animator=animator,loop="CRFHold",release="CRFRelease"} end
    if key=="X" then
        return {animator=animator,loop=mode=="Fist" and "CRFistXHold" or mode=="Dagger" and "CRDaggerXHold" or "CRXHold",
            release=mode=="Fist" and "CRFistXRelease" or mode=="Dagger" and "CRDaggerXRelease" or "CRXRelease"}
    end
    if key=="C" then
        return {animator=animator,loop=mode=="Fist" and "CRFistCHold" or mode=="Dagger" and "CRDaggerCHold" or "CRCHold",
            release=mode=="Fist" and "CRFistCRelease" or mode=="Dagger" and "CRDaggerCRelease" or "CRCRelease"}
    end
    return nil
end
return config
