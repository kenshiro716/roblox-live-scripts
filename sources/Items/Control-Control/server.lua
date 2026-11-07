-- Control rework: all combat, room bounds and cooldown decisions are server-owned.
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local Debris = game:GetService("Debris")
local kitClass = require(SS:WaitForChild("fruitkit"))
local melee = require(SS:WaitForChild("meleekit"))
local hitbox = require(SS:WaitForChild("hitbox"))
local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
tool:SetAttribute("MovesetToolUid", Http:GenerateGUID(false))
tool:SetAttribute("WeaponType", "Demon Fruit")
tool:SetAttribute("MovesetV2", true)
tool.RequiresHandle = false
local room, roomCharacter, expires, mode = nil, nil, 0, "Dagger"
local meter, combo, comboAt = 0, 0, 0
local started, castMode, proxies, cubes = {}, {}, {}, {}
local ended, kit = false, nil
local MAX_CUBES = 3
local function finite(v)
    return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 1e7 and math.abs(v.Y) < 1e7 and math.abs(v.Z) < 1e7
end
local function marker(name, value, parent)
    local o = Instance.new("BoolValue")
    o.Name = name; o.Value = value; o.Parent = parent
    return o
end
local function params(player, character, root, extra)
    local p = {Player=player, Character=character, Root=root, hrp=root, Origin=root.Position}
    for k,v in pairs(extra or {}) do p[k]=v end
    return p
end
local function fx(name, p) kit:play("ControlRework." .. name, p) end
local function current(character, point)
    return room and room.Parent == character and character == roomCharacter
        and character:GetAttribute("ControlRoomActive") == true
        and (point - room:GetAttribute("CFrame").Position).Magnitude <= room:GetAttribute("Radius")
end
local function aim(root, limit, inside)
    local target = tool.MousePos.Value
    if not finite(target) then target = root.Position + root.CFrame.LookVector * 30 end
    local offset = target-root.Position
    if offset.Magnitude > limit then target=root.Position+offset.Unit*limit end
    if inside and room then
        local center=room:GetAttribute("CFrame").Position
        local v=target-center
        if v.Magnitude>room:GetAttribute("Radius")-3 then target=center+v.Unit*(room:GetAttribute("Radius")-3) end
    end
    return target
end
local function facing(root, target)
    local delta=target-root.Position
    if delta.Magnitude < 0.1 then delta=root.CFrame.LookVector end
    return CFrame.lookAt(root.Position,root.Position+delta.Unit)
end
local function spend(character,key)
    return melee.spend(character,data.Cost[key] or 0)
end
local function updateMeter(character, amount)
    meter=math.clamp(meter+amount,0,100)
    tool:SetAttribute("MaximumOutput",meter)
    tool:SetAttribute("MaximumOutputMax",100)
    if character then character:SetAttribute("ControlMaximumOutput",meter) end
end
local function strike(character, position, radius, damage, stun)
    local landed={}
    for _,t in ipairs(hitbox.sphere(character,position,radius)) do
        if kit:hit(t.humanoid,damage,t.root) then
            melee.stun(t.model,stun or 0.3)
            table.insert(landed,t)
        end
    end
    return landed
end
local function line(character, origin, target, radius, damage)
    local landed={}
    for _,t in ipairs(hitbox.line(character,origin,target,radius)) do
        if kit:hit(t.humanoid,damage,t.root) then
            melee.stun(t.model,0.45)
            table.insert(landed,t)
        end
    end
    return landed
end
local function targetAt(character, origin, target, radius)
    local t=melee.firstline(character,origin,target,radius)
    return t and (not current(character,origin) or current(character,t.root.Position)) and t or nil
end
local function clearCubes()
    for _,c in ipairs(cubes) do
        if c.proxy.Parent then c.proxy:SetAttribute("Exploding",true); Debris:AddItem(c.proxy,1) end
    end
    table.clear(cubes)
end
local function setMode(player, character, root, newMode, override)
    mode=newMode
    tool:SetAttribute("ControlMode",mode)
    character:SetAttribute("ControlMode",mode)
    fx("DomainCharge",params(player,character,root,{Dagger="Equip",CurrentMode=mode,Override=override==true}))
end
local function closeRoom()
    local character=roomCharacter
    if character then
        character:SetAttribute("ControlRoomActive",false)
        character:SetAttribute("ControlMode","Base")
        character:SetAttribute("AuraActive",false)
    end
    if room then room:SetAttribute("Active",false); Debris:AddItem(room,1.5) end
    room=nil; roomCharacter=nil; expires=0
    tool:SetAttribute("ControlMode","Base")
    clearCubes()
end
local function openRoom(player, character, root, held)
    closeRoom()
    roomCharacter=character
    room=Instance.new("Folder")
    room.Name="__Room"
    local radius=math.clamp(data.Room.MinRadius+held*data.Room.ChargeGrowth,data.Room.MinRadius,data.Room.MaxRadius)
    room:SetAttribute("CFrame",CFrame.new(root.Position))
    room:SetAttribute("Radius",radius)
    room:SetAttribute("MaxRadius",radius)
    room:SetAttribute("HoldDuration",math.max(0.25,held))
    room:SetAttribute("Active",true)
    room.Parent=character
    character:SetAttribute("ControlRoomActive",true)
    expires=os.clock()+data.Room.Duration
    room:SetAttribute("ExpiresAt",workspace:GetServerTimeNow()+data.Room.Duration)
    fx("Domain",{player,character,1,false})
    setMode(player,character,root,"Dagger",true)
end
local function makeCube(player, character, root)
    if #cubes >= MAX_CUBES then return end
    local point=aim(root,160,true)
    local result=workspace:Raycast(point+Vector3.new(0,30,0),Vector3.new(0,-100,0),melee.rayparams(character))
    if not result then return end
    local proxy=Instance.new("Folder")
    proxy.Name=Http:GenerateGUID(false)
    proxy.Parent=room
    proxy:SetAttribute("SizeScale",1)
    local holding=marker("Holding",true,proxy)
    task.delay(0.15,function() if holding.Parent then holding.Value=false end end)
    table.insert(cubes,{proxy=proxy,point=result.Position})
    fx("M1.Fist_Inside",params(player,character,root,{
        Proxy=proxy,MousePos=point,Holding=holding,
        RayCastResult={Position=result.Position,Normal=result.Normal,Instance=result.Instance}
    }))
end
local function throwCubes(player,character,root,target)
    local previous=cubes; cubes={}
    for _,c in ipairs(previous) do
        if c.proxy.Parent then
            c.proxy:SetAttribute("Throwing",true)
            fx("M1.Fist_Inside",params(player,character,root,{
                ForceThrow=true,DataModel=c.proxy.Name,ShootPoint=target
            }))
            line(character,c.point,target,8,data.Damage.FistM1)
            strike(character,target,10,data.Damage.FistM1,0.4)
            Debris:AddItem(c.proxy,2)
        end
    end
end
local function cleanupCast(key)
    local p=proxies[key]
    if p then Debris:AddItem(p,10); proxies[key]=nil end
end
local function beginCast(player,character,root,key)
    started[key]=os.clock()
    castMode[key]=current(character,root.Position) and mode or "Base"
    local m=castMode[key]
    if key=="Z" then
        if not room then fx("DomainCharge",params(player,character,root,{Duration=3})) end
    elseif key=="X" and m~="Fist" then
        fx(m=="Base" and "X_Outside" or "NewDaggerX",params(player,character,root,{Stage=1,Holding=kit.effectholding}))
    elseif key=="C" then
        if m=="Base" then fx("C_Outside",params(player,character,root,{}))
        elseif m=="Dagger" then fx("CDagger",params(player,character,root,{Stage=1,Holding=kit.effectholding}))
        else
            local proxy=Instance.new("Folder"); proxy.Name="ControlPillars"; proxy.Parent=room
            local target=aim(root,180,true)
            for i=1,6 do
                local point=root.Position:Lerp(target,i/6)
                local ray=workspace:Raycast(point+Vector3.new(0,40,0),Vector3.new(0,-110,0),melee.rayparams(character))
                local v=Instance.new("CFrameValue"); v.Name="Pillar_"..i
                v.Value=CFrame.lookAt(ray and ray.Position or point,target+Vector3.new(0,3,0))
                v:SetAttribute("RayHitMaterial",ray and ray.Material or Enum.Material.Slate)
                v:SetAttribute("RayHitColor",ray and ray.Instance.Color or Color3.fromRGB(90,90,100))
                v:SetAttribute("RayPosition",ray and ray.Position or point)
                v:SetAttribute("RayNormal",ray and ray.Normal or Vector3.yAxis)
                v:SetAttribute("CreatedAt",workspace:GetServerTimeNow())
                v.Parent=proxy
            end
            proxies.C=proxy
            fx("CFist",params(player,character,root,{Stage=1,Holding=kit.effectholding,Proxy=proxy,Total=6}))
        end
    elseif key=="F" then
        fx("F",params(player,character,root,{Stage=1,Holding=kit.effectholding}))
    elseif key=="V" and m~="Base" then
        fx("V_Normal",params(player,character,root,{Stage=1,Holding=kit.effectholding,RoomFolder=room}))
    end
end
local function releaseCast(player,character,root,key,shot)
    if tool.Parent~=character or character.Humanoid.Health<=0 then cleanupCast(key); return end
    local held=math.clamp(os.clock()-(started[key] or os.clock()),0,3)
    started[key]=nil
    tool:SetAttribute("LastControlMove",key)
    tool:SetAttribute("ControlMoveCount",(tool:GetAttribute("ControlMoveCount") or 0)+1)
    local m=castMode[key] or "Base"
    local inside=current(character,root.Position)
    local target=aim(root,inside and 220 or 120,inside)
    local cf=facing(root,target)
    if key=="Z" then
        if room then
            if held>=0.65 then closeRoom()
            elseif inside then setMode(player,character,root,mode=="Dagger" and "Fist" or "Dagger",false)
            else
                room:SetAttribute("CFrame",CFrame.new(root.Position))
                fx("DomainCharge",params(player,character,root,{ShiftRoom=true}))
            end
        else openRoom(player,character,root,held) end
        kit.busyuntil=os.clock()+0.35
        return
    end
    if m~="Base" and not inside then cleanupCast(key); return end
    kit.busyuntil=os.clock()+0.4
    if key=="X" then
        local victim=targetAt(character,root.Position,target,8)
        if m=="Base" then
            fx("X_Outside",params(player,character,root,{Stage=2,StartCFrame=cf,EndCFrame=CFrame.new(target),
                Distance=(target-root.Position).Magnitude,Duration=0.35,ThrowDirection=cf.LookVector,
                EnemyChar=victim and victim.model,KnockCFrame=CFrame.new(target+cf.LookVector*12),KnifeDistance=120}))
            line(character,root.Position,target,7,data.Damage.X)
        elseif m=="Dagger" then
            fx("NewDaggerX",params(player,character,root,{Stage=2,StartCFrame=cf,EndPoint=target,
                MaxDistance=220,EnemyChar=victim and victim.model,UpCFrame=cf+Vector3.new(0,12,0),
                PushCFrame=CFrame.new(target+cf.LookVector*15),EnemyCFrame=victim and victim.root.CFrame or CFrame.new(target),
                EnemyCFrame2=CFrame.new(target+Vector3.new(0,10,0)),StartTime=workspace:GetServerTimeNow()}))
            line(character,root.Position,target,10,data.Damage.X*1.25)
        else
            local targets={} for _,c in ipairs(cubes) do table.insert(targets,c.proxy) end
            fx("XFist",params(player,character,root,{Stage=1,CFrame=cf,XZCFrame=cf,
                TargetObjects=targets,Mouse=target,DelayTimestamp=workspace:GetServerTimeNow(),
                EnemyChar=victim and victim.model}))
            strike(character,target,24,data.Damage.X*1.15,0.65)
            throwCubes(player,character,root,target)
        end
    elseif key=="C" then
        if m=="Base" then
            fx("C_Outside",params(player,character,root,{StateChange=workspace:GetServerTimeNow(),StartCFrame=cf}))
            line(character,root.Position,target,9,data.Damage.C)
            task.delay(0.45,function() if character.Parent then line(character,target,root.Position,9,data.Damage.C*0.5) end end)
        elseif m=="Dagger" then
            local victim=targetAt(character,root.Position,target,12)
            local folder=Instance.new("Folder")
            folder.Name="ControlGammaSlashes"; folder.Parent=room
            for i=1,3 do
                local slash=Instance.new("CFrameValue")
                slash.Name="Slash_"..i; slash.Value=cf*CFrame.new((i-2)*4,0,0)
                slash:SetAttribute("Id",Http:GenerateGUID(false)); slash.Parent=folder
                local origin=slash.Value.Position
                line(character,origin,target,10,data.Damage.C/3)
                task.delay(0.6,function() if slash.Parent then slash:SetAttribute("Exploded",CFrame.new(target)) end end)
            end
            fx("CDagger",params(player,character,root,{Stage=2,ProxyFolder=folder,MousePos=target,Speed=160}))
            Debris:AddItem(folder,4)
            if victim then
                task.delay(0.7,function()
                    if victim.model.Parent and root.Parent then
                        fx("CDagger",params(player,character,root,{Stage=3,EnemyChar=victim.model,Delay=0.5,Speed=160}))
                        strike(character,victim.root.Position,12,data.Damage.C*0.4,0.8)
                    end
                end)
            end
        else
            local proxy=proxies.C
            if proxy then
                for _,v in ipairs(proxy:GetChildren()) do if v:IsA("CFrameValue") then
                    strike(character,v.Value.Position+Vector3.new(0,7,0),14,data.Damage.C/3,0.5)
                end end
            end
            cleanupCast("C")
        end
    elseif key=="F" then
        local origin=root.CFrame
        local victim=targetAt(character,root.Position,target,7)
        local destination=target
        if inside and victim and current(character,victim.root.Position) and not victim.root.Anchored then
            destination=victim.root.Position
            victim.root.CFrame=origin
        end
        local ray=workspace:Raycast(root.Position,destination-root.Position,melee.rayparams(character))
        if ray then destination=ray.Position+ray.Normal*4 end
        local endCF=CFrame.lookAt(destination+Vector3.new(0,3,0),destination+Vector3.new(0,3,0)+cf.LookVector)
        local proxy=Instance.new("CFrameValue"); proxy.Name="ControlTransmutation"; proxy.Value=endCF
        proxy.Parent=workspace._WorldOrigin
        fx("F",params(player,character,root,{Stage=2,Holding=kit.effectholding,StartCFrame=origin,
            ProxyCFrame=proxy,EndCFrame=endCF,Humanoid=character.Humanoid,KnifeLanded=true}))
        root.CFrame=endCF
        root.AssemblyLinearVelocity=Vector3.zero
        Debris:AddItem(proxy,2)
        if victim then kit:hit(victim.humanoid,data.Damage.F,victim.root) end
    elseif key=="V" then
        if not inside then return end
        local victim=targetAt(character,root.Position,target,20) or melee.firstnear(character,target,25)
        local finish=CFrame.new(target+cf.LookVector*18)
        if held>=1.2 and meter>=100 then
            updateMeter(character,-100)
            local caught={}
            for _,v in ipairs(hitbox.sphere(character,target,math.min(60,room:GetAttribute("Radius")))) do
                if current(character,v.root.Position) and kit:canhit(v.model) then
                    local owner=Players:GetPlayerFromCharacter(v.model)
                    if owner then table.insert(caught,owner) end
                    task.delay(5,function()
                        if v.humanoid.Parent and character.Parent then kit:hit(v.humanoid,data.Damage.Ultimate,v.root) end
                    end)
                end
            end
            fx("V_Cutscene",params(player,character,root,{Stage=2,CaughtPlayers=caught}))
            kit.busyuntil=os.clock()+8
            task.delay(9,function()
                if root.Parent then root.Anchored=false end
                if character.Parent then character:SetAttribute("InControlCutscene",false) end
            end)
        else
            fx("V_Normal",params(player,character,root,{Stage=2,RoomFolder=room,StartCFrame=cf,
                Target=victim and victim.model,TeleportCFrame=CFrame.new(target),
                FinalCFrames={RushTeleportCFrame=cf,KnockbackCFrame=finish,FinalSlashCFrame=finish}}))
            if victim and current(character,victim.root.Position) then
                for i=1,6 do task.delay(i*0.18,function()
                    if character.Parent and victim.humanoid.Parent then kit:hit(victim.humanoid,data.Damage.V/6,victim.root) end
                end) end
            else strike(character,target,30,data.Damage.V,1) end
            kit.busyuntil=os.clock()+3
        end
    end
end
kit=kitClass.new(tool,{
    holdkeys={Z=true,X=true,C=true,V=true,F=true},maxhold=3,
    canhold=function(player,character,root,key)
        if key=="V" and not current(character,root.Position) then return false end
        return spend(character,key)
    end,
    onholdstart=beginCast,onrelease=releaseCast,
    onm1=function(player,character,root)
        local stun=character:FindFirstChild("Stun")
        if stun and stun.Value>0 then return end
        if not spend(character,"TAP") then return end
        local inside=current(character,root.Position)
        local target=aim(root,inside and 150 or 30,inside)
        if inside and mode=="Fist" then
            if #cubes>0 then throwCubes(player,character,root,target)
            else makeCube(player,character,root) end
        else
            combo=os.clock()-comboAt>1.2 and 1 or combo%3+1; comboAt=os.clock()
            if inside then
                fx("M1.Dagger_Inside",params(player,character,root,{Cast=true,HitCF=CFrame.new(target),PlaneCF=facing(root,target)}))
                line(character,root.Position,target,5,data.Damage.DaggerM1)
            else
                fx("M1.Dagger_Outside",params(player,character,root,{Combo=combo,StartCFrame=root.CFrame}))
                line(character,root.Position,root.Position+root.CFrame.LookVector*14,5,data.Damage.BaseM1)
            end
        end
    end,
    onhit=function(amount,humanoid) updateMeter(roomCharacter,math.min(8,amount*0.03)) end,
    onequip=function(player,character)
        local root=character:FindFirstChild("HumanoidRootPart")
        if root then
            local inside=current(character,root.Position)
            setMode(player,character,root,inside and mode or "Dagger",true)
            if not inside then tool:SetAttribute("ControlMode","Base"); character:SetAttribute("ControlMode","Base") end
        end
        updateMeter(character,0)
    end,
    onunequip=function(player)
        for key in pairs(proxies) do cleanupCast(key) end
        if player and player.Character then
            local c=player.Character; local root=c:FindFirstChild("HumanoidRootPart")
            if root then fx("DomainCharge",params(player,c,root,{Dagger="Unequip",Override=true})) end
        end
    end,
    onpassiveend=function() closeRoom() end,
})
local nativeHit=kit.hit
function kit:hit(humanoid,amount,part)
    local character=self:attacker()
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local victim=humanoid and humanoid.Parent
    local victimRoot=victim and victim:FindFirstChild("HumanoidRootPart")
    if root and current(character,root.Position) and victimRoot and not current(character,victimRoot.Position) then return false end
    return nativeHit(self,humanoid,amount,part)
end
local connection
connection=Run.Heartbeat:Connect(function()
    if ended then return end
    if room then
        local humanoid=roomCharacter and roomCharacter:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health<=0 or not roomCharacter:IsDescendantOf(workspace) or os.clock()>=expires then closeRoom() end
    end
end)
tool.Destroying:Connect(function()
    ended=true; closeRoom()
    for key in pairs(proxies) do cleanupCast(key) end
    connection:Disconnect()
end)
tool:SetAttribute("ControlServerReady",true)
