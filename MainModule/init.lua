local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local FakePath = Storage:FindFirstChild("DefaultChatSystemChatEvents")

local resume, create = coroutine.resume, coroutine.create
local insert, clear = table.insert, table.clear
local signals = {}
local function logsignal(signal)
    insert(signals, signal)
end

local function inew(inst, par, props)
    local i = Instance.new(inst)
    for ind, val in next, props or {} do
        pcall(function()
            i[ind] = val
        end)
    end
    i.Parent = par
    return i
end

local function initclient(host, client, stand)
    local function setattrs(s, attrs)
        for i,v in next, attrs do
            s:SetAttribute(i,v)
        end
    end
    local function WFCOC(Parent, Class)
        local obj = Parent:FindFirstChildOfClass(Class)
        while not obj do
            obj = Parent.ChildAdded:Wait()
        end
        return obj
    end
    resume(create(function()
        local localscript = script:FindFirstChildOfClass("LocalScript")
        localscript.Name = client.Name
        setattrs(localscript, {
            HostName = host.Name,
            HostID = host.UserId,
            Standing = stand
        })
        localscript.Parent = WFCOC(client, "PlayerGui")
    end))
end

local function Server_init(Player)
    local Character = Player.Character
    if not Character then
        Player:LoadCharacter()
        Character = Player.Character
    end
    Character.Archivable = true
    local StorageCharacter = Character:Clone()
    local CharacterObjects = StorageCharacter:GetDescendants()
    for i = 1, #CharacterObjects do
        local io = CharacterObjects[i]
        if io:IsA("LuaSourceContainer") or io:IsA("ForceField") then
            io:Destroy()
        end
    end
    Character.Archivable = false
    local Root = StorageCharacter:WaitForChild("HumanoidRootPart")
    local Standing = Root.Position
    local CharacterRemote = inew("RemoteFunction", FakePath or Storage, {Name = "GetCharacterInit"})
    CharacterRemote.OnServerInvoke = function()
        return StorageCharacter:Clone()
    end
    local ServerRemote = inew("RemoteEvent", FakePath or Storage, {Name = "SendCharacterData"})
    ServerRemote.OnServerEvent:Connect(function(player, ...)
        if player.UserId == Player.UserId then
            local arg1 = ({...})[1]
            if arg1 == "Stop" then

            end
            ServerRemote:FireAllClients(...)
        end
    end)
    
    local function Chatted(player, str)
        local str_tab = str:split(' ')
        local s1 = str_tab[1] and str_tab[1]:lower()
        local s2 = str_tab[2] and str_tab[2]:lower()
        if s1 == "/e" and s2 == "stop" then
            CharacterRemote:Destroy()
            ServerRemote:Destroy()
            for i = 1, #signals do
                pcall(function()
                    signals[i]:Disconnect()
                end)
            end
            clear(signals)
        end
    end
    local PlayerList = Players:GetPlayers()
    for i = 1, #PlayerList do
        initclient(Player, PlayerList[i], Standing)
    end
    logsignal(Players.PlayerAdded:Connect(function(player)
        if player.UserId == Player.UserId then
            logsignal(player.Chatted:Connect(function(str)
                Chatted(player, str)
            end))
        end
        initclient(Player, player, Standing)
    end))
end

return function (PlayerName)
    local Player = Players:FindFirstChild(PlayerName)
    if Player then
        Server_init(Player)
    end
end