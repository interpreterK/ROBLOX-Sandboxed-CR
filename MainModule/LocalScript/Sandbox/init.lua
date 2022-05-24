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

	local real = {game = game}
	local function fakeEvent()
		local Bind = Instance.new("BindableEvent")
		return Bind.Event
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
	end
	local MouseEvents = {"Button1Down","Button1Up","Button2Down","Button2Up","KeyDown","KeyUp"}
	if IsTheReplicator then
		local Mouse = Player:GetMouse()
		for i = 1, #MouseEvents do
			Mouse[MouseEvents[i]]:Connect(function(...)
				fakeRemote:FireServer(MouseEvents[i], ...)
			end)
		end
	else
		local Mouse = {}
		for i = 1, #MouseEvents do
			Mouse[MouseEvents[i]] = fakeEvent()
		end
		function Mouse.GetMouse()
			return Mouse
		end
	end
	
end