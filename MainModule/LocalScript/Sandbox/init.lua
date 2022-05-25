local S = setmetatable({},{__index = function(_,s) return game:GetService(s) end})
local Players = S.Players
local Storage = S.ReplicatedStorage
local RS = S.RunService
local FakePath = Storage:FindFirstChild("DefaultChatSystemChatEvents") or Storage
local fakeCharacterRemote, fakeRemote = FakePath:WaitForChild("GetCharacterInit"), FakePath:WaitForChild("SendCharacterData")

local ReplicateInfo = fakeCharacterRemote:InvokeServer()
local fakeCharacter = ReplicateInfo.Character
local Player = Players.LocalPlayer
local IsTheReplicator = Player.UserId == ReplicateInfo.Player.UserId
  
return function()
	local real = {game = game, workspace = workspace, script = script}
	local Rem_Actions = {}
	local function FakeSignal()
		return Instance.new("BindableEvent")
	end
	local function newObject(real)
		local Object = {}
		Object.__index = function(self,ind)
			return rawget(self,ind) or real[ind]
		end
		Object.__newindex = function(_,ind,val)
			real[ind] = val
		end
		Object.__tostring = function()
			return real.Name
		end
		Object.__metatable = getmetatable(real)
		return Object
	end
	local function newSignalObject(SignalObj)
		local RBXScriptSignal = newproxy(true)
		local Signal = getmetatable(RBXScriptSignal)
		Signal.__index = function(_,ind)
			if ind == "connect" then
				return SignalObj.Event
			end
			if ind == "wait" then
				return Signal.Event:Wait()
			end
			return nil
		end
		Signal.__metatable = nil
		return Signal
	end
	local Mouse, MouseEvents = {}, {"Button1Down","Button1Up","Button2Down","Button2Up","KeyDown","KeyUp"}
	local workspace = real.workspace
	if IsTheReplicator then
		local Mouse = Player:GetMouse()
		for i = 1, #MouseEvents do
			Mouse[MouseEvents[i]]:Connect(function(Key)
				fakeRemote:FireServer({
					Action = "Mouse",
					Event = MouseEvents[i],
					Key = Key
				})
			end)
		end
		local Root = Player.Character:WaitForChild("HumanoidRootPart")
		RS.Heartbeat:Connect(function()
			fakeRemote:FireServer({
				Action = "Movement",
				CFrame = Root.CFrame,
				Velocity = Root:GetVelocityAtPosition(Root.Position)
			})
		end)
	else
		for i = 1, #MouseEvents do
			Mouse[MouseEvents[i]] = setmetatable({}, newSignalObject(FakeSignal()))
		end
		Mouse.GetMouse = Mouse
		local CurrentCamera = setmetatable({}, {
			__index = function(self,i)
				return rawget(self,i)
			end,
			__newindex = function(self,i,v)
				rawset(self,i,v)
			end
		})
		workspace = setmetatable({CurrentCamera = CurrentCamera}, newObject(workspace))

		function Rem_Actions.Mouse(args)
			Mouse[args.Event]:Fire(args.Key)
		end
	end
	local RunService = {}
	function RunService.IsServer()
		return true
	end
	function RunService.IsClient()
		return false
	end
	local Services = {
		Players = setmetatable({
			LocalPlayer = setmetatable(Mouse, newObject(ReplicateInfo.Player)),
			localPlayer = setmetatable(Mouse, newObject(ReplicateInfo.Player))
		}, newObject(Players)),
		RunService = setmetatable(RunService, newObject(RS)),
		Workspace = workspace,
		workspace = workspace
	}
	local game = setmetatable(Services, newObject(real.game))
	function game:GetService(service)
		return Services[service] or real.game:GetService(service)
	end
	function game:service(...)
		return self:GetService(...)
	end
	local script = Instance.new("Script")
	script.Name = getfenv(2).script.Name
	script.Parent = getfenv(2).script.Parent
	local srcChildren = getfenv(2).script:GetChildren()
	for i = 1, #srcChildren do
		if srcChildren[i] ~= real.script then
			srcChildren[i].Parent = script
		end
	end
	fakeRemote.OnClientEvent:Connect(function(args)
		local act = Rem_Actions[args.Action]
		if act then
			act(args)
		end
	end)
	local env = {
		game = game,
		Game = game,
		script = script,
		workspace = workspace,
		Workspace = workspace
	}
	for i,v in next, env do
		getfenv(2)[i] = v
	end
end