--!strict
-- Belépési pont a szerveren: felépíti a pályát, létrehozza a lányt, lejátssza
-- a fejezetet, majd mindent töröl és elölről kezdi.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local Companion = require(script.Parent:WaitForChild("Companion"))
local Director = require(script.Parent:WaitForChild("Director"))

-- Ezen az egy csatornán küld a szerver mindent a klienseknek (szöveg, cél, effektek).
local storyEvent = Instance.new("RemoteEvent")
storyEvent.Name = "StoryEvent"
storyEvent.Parent = ReplicatedStorage

while true do
	local map = MapBuilder.build()
	local companion = Companion.new(map.companionStart, map.folder)

	-- Mindenki friss karakterrel indul az előszobában.
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
	storyEvent:FireAllClients("Reset")

	local ok, problem = pcall(Director.run, map, companion, storyEvent)
	if not ok then
		warn("[Main] Hiba a fejezet futása közben:", problem)
		task.wait(5)
	end

	companion:destroy()
	map.folder:Destroy()
end
