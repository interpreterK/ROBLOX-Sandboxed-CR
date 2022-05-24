local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local FakePath = Storage:FindFirstChild("DefaultChatSystemChatEvents") or Storage
local fakeCharacterRemote, fakeRemote = FakePath:WaitForChild("GetCharacterInit"), FakePath:WaitForChild("SendCharacterData")

return function ()
	local ReplicateInfo = fakeCharacterRemote:InvokeServer()
	local fakeCharacter = ReplicateInfo.Character
	local Player = Players.LocalPlayer
	local IsTheReplicator = Player.Name == fakeCharacter.Name

	local real = {game = game, workspace = workspace}
	local function fakeEvent()
		return Instance.new("BindableEvent").Event
	end
	local function newObject(real)
		local Object = {}
		Object.__metatable = "This metatable is locked"
		Object.__index = function(self,ind)
			return rawget(self,ind) or real[ind]
		end
		Object.__newindex = function(_,ind,val)
			real[ind] = val
		end
		Object.__tostring = function()
			return real.Name
		end
	end
	local Mouse, MouseEvents = {}, {"Button1Down","Button1Up","Button2Down","Button2Up","KeyDown","KeyUp"}
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
	else
		for i = 1, #MouseEvents do
			Mouse[MouseEvents[i]] = fakeEvent()
		end
		function Mouse.GetMouse()
			return Mouse
		end
		fakeRemote.OnClientEvent:Connect(function(args)
			if args.Action == "Mouse" then
				Mouse[args.Event]:Fire(args.Key)
				return
			end
		end)
	end
	local Services = {
		Players = setmetatable({
			LocalPlayer = 
		}, newObject(Players))
	}
	local game = setmetatable(Services, newObject(real.game))
	function game:GetService(service)
		return Services[service] or real.game:GetService(service)
	end
	function game:service(...) return self:GetService(...) end
	
	local env = {
		game = game
	}
	for i,v in next, env do
		getfenv(2)[i] = v
	end
end