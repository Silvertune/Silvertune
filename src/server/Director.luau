--!nonstrict
-- A "rendező": az első fejezet története fentről lefelé olvasható formában.
-- A Director.run() addig fut, amíg a játékosok ki nem jutnak, utána visszatér,
-- és a Main újraindítja a fejezetet.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Story = require(Shared:WaitForChild("Story"))

local Director = {}

type Line = { string }

function Director.run(map: any, companion: any, storyEvent: RemoteEvent)
	local connections: { RBXScriptConnection } = {}
	local sounds: { Sound } = {}
	local currentObjective = ""
	local hunting = false

	local function track(connection: RBXScriptConnection)
		table.insert(connections, connection)
	end

	---------------------------------------------------------------------------
	-- Segédfüggvények
	---------------------------------------------------------------------------

	-- Hang lejátszása; ha nincs beállítva ID a Configban, nem csinál semmit.
	local function playSound(id: string, parent: Instance, looped: boolean?): Sound?
		if id == "" then
			return nil
		end
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Looped = looped == true
		sound.Parent = parent
		sound:Play()
		table.insert(sounds, sound)
		return sound
	end

	-- Egy sor szöveg mindenkinek; megvárja, amíg el lehet olvasni.
	local function say(line: Line)
		local duration = 1.5 + #line[2] * 0.05
		storyEvent:FireAllClients("Dialogue", { speaker = line[1], text = line[2], duration = duration })
		task.wait(duration + 0.3)
	end

	local function sayAll(lines: { Line })
		for _, line in lines do
			say(line)
		end
	end

	-- Megjegyzés, ami nem állítja meg a történetet (egy játékosnak vagy mindenkinek).
	local function remark(line: Line, player: Player?)
		local payload = { speaker = line[1], text = line[2], duration = 3.5 }
		if player then
			storyEvent:FireClient(player, "Dialogue", payload)
		else
			storyEvent:FireAllClients("Dialogue", payload)
		end
	end

	local function setObjective(text: string)
		currentObjective = text
		storyEvent:FireAllClients("Objective", text)
	end

	local function getPrompt(part: Instance): ProximityPrompt
		return part:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	end

	-- Megvárja, amíg valaki használja a tárgyat, és visszaadja, hogy ki volt az.
	local function waitForUse(part: Instance): Player
		local prompt = getPrompt(part)
		prompt.Enabled = true
		local player = prompt.Triggered:Wait()
		prompt.Enabled = false
		return player
	end

	-- Megvárja, amíg az összes tárgyat összeszedik; közben számolja a célkiírásban.
	local function collectAll(items: { Part }, objectiveFormat: string)
		local total = #items
		local count = 0
		local finished = Instance.new("BindableEvent")
		setObjective(string.format(objectiveFormat, count, total))

		for _, item in items do
			local prompt = getPrompt(item)
			prompt.Enabled = true
			prompt.Triggered:Once(function()
				count += 1
				playSound(Config.Sounds.Pickup, map.folder)
				item:Destroy()
				setObjective(string.format(objectiveFormat, count, total))
				if count >= total then
					finished:Fire()
				end
			end)
		end

		finished.Event:Wait()
		finished:Destroy()
	end

	local function flicker(lamp: any, times: number)
		task.spawn(function()
			for _ = 1, times do
				lamp.light.Enabled = false
				task.wait(0.08 + math.random() * 0.15)
				lamp.light.Enabled = true
				task.wait(0.05 + math.random() * 0.2)
			end
		end)
	end

	local function setCozyLighting()
		Lighting.ClockTime = 0
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(42, 36, 44)
		Lighting.ExposureCompensation = -0.4
		Lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 45)
		Lighting.FogEnd = 100000
	end

	local function setDarkLighting()
		Lighting.Ambient = Color3.fromRGB(10, 10, 16)
		Lighting.OutdoorAmbient = Color3.fromRGB(5, 5, 10)
		Lighting.FogColor = Color3.fromRGB(0, 0, 0)
		Lighting.FogEnd = 70
		for _, lamp in map.lamps do
			lamp.light.Brightness = 0.12
			lamp.light.Color = Color3.fromRGB(255, 70, 90)
			lamp.part.Color = Color3.fromRGB(120, 30, 45)
		end
	end

	-- Zseblámpa-szerű fény a játékoson az üldözés alatt.
	local function giveLight(character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if root and not root:FindFirstChild("HuntLight") then
			local light = Instance.new("PointLight")
			light.Name = "HuntLight"
			light.Range = 20
			light.Brightness = 1
			light.Color = Color3.fromRGB(230, 235, 255)
			light.Parent = root
		end
	end

	local function setupCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.WalkSpeed = Config.PlayerWalkSpeed
		end
		if hunting then
			giveLight(character)
		end
	end

	local function setupPlayer(player: Player)
		player.CameraMode = if Config.FirstPerson then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
		player:SetAttribute("SafeUntil", 0)
		track(player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end))
		if player.Character then
			setupCharacter(player, player.Character)
		end
		-- Aki később csatlakozik, az is lássa az aktuális célt.
		if currentObjective ~= "" then
			storyEvent:FireClient(player, "Objective", currentObjective)
		end
	end

	---------------------------------------------------------------------------
	-- Előkészítés
	---------------------------------------------------------------------------

	setCozyLighting()

	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	track(Players.PlayerAdded:Connect(setupPlayer))

	-- Megvárjuk az első játékost és a karakterét.
	while #Players:GetPlayers() == 0 do
		Players.PlayerAdded:Wait()
	end
	local firstPlayer = Players:GetPlayers()[1]
	if firstPlayer and not firstPlayer.Character then
		firstPlayer.CharacterAdded:Wait()
	end
	task.wait(2)

	---------------------------------------------------------------------------
	-- 1. Érkezés
	---------------------------------------------------------------------------

	setObjective(Story.Objectives.Welcome)
	sayAll(Story.Intro)

	-- A raktár ajtaja végig megnyomható; hogy mi történik, az a történet állásától függ.
	local hasStorageKey = false
	local lastStorageRemark = 0
	local storagePrompt = getPrompt(map.storageDoor)
	storagePrompt.Enabled = true
	track(storagePrompt.Triggered:Connect(function(player)
		if hasStorageKey then
			storagePrompt.Enabled = false
			map.storageDoor.CanCollide = false
			map.storageDoor.Transparency = 1
			remark(Story.StorageOpened)
			setObjective(Story.Objectives.FrontKey)
		elseif os.clock() - lastStorageRemark > 4 then
			lastStorageRemark = os.clock()
			remark(if hunting then Story.StorageLockedHunt else Story.StorageLocked, player)
		end
	end))

	---------------------------------------------------------------------------
	-- 2. Teázás
	---------------------------------------------------------------------------

	companion:setMode("Follow")
	collectAll(map.cups, Story.Objectives.Cups)
	sayAll(Story.TeaReady)

	setObjective(Story.Objectives.Table)
	waitForUse(map.kitchenTable)
	flicker(map.lamps[3], 4) -- a konyhai lámpa megrebben: az első furcsaság
	sayAll(Story.TeaDone)

	---------------------------------------------------------------------------
	-- 3. Plüssök
	---------------------------------------------------------------------------

	collectAll(map.plushies, Story.Objectives.Plushies)
	for _, lamp in map.lamps do
		flicker(lamp, 3)
	end
	storyEvent:FireAllClients("Effect", "Glitch")
	sayAll(Story.PlushiesDone)

	---------------------------------------------------------------------------
	-- 4. A zenedoboz
	---------------------------------------------------------------------------

	setObjective(Story.Objectives.MusicBox)
	waitForUse(map.musicBox)
	local tune = playSound(Config.Sounds.MusicBox, map.musicBox, true)
	sayAll(Story.MusicBoxWound)

	map.note.Transparency = 0
	setObjective(Story.Objectives.Note)
	local reader = waitForUse(map.note)
	storyEvent:FireClient(reader, "Note", Story.Note)
	-- A cetli utána is újraolvasható.
	local notePrompt = getPrompt(map.note)
	notePrompt.Enabled = true
	track(notePrompt.Triggered:Connect(function(player)
		storyEvent:FireClient(player, "Note", Story.Note)
	end))
	task.wait(8)

	---------------------------------------------------------------------------
	-- 5. Üldözés és szökés
	---------------------------------------------------------------------------

	companion:setMode("Idle")
	if tune then
		tune:Stop()
	end
	say(Story.HuntStart[1])

	hunting = true
	setDarkLighting()
	playSound(Config.Sounds.LightsOut, map.folder)
	playSound(Config.Sounds.Ambience, map.folder, true)
	storyEvent:FireAllClients("Effect", "Glitch")
	for _, player in Players:GetPlayers() do
		if player.Character then
			giveLight(player.Character)
		end
	end

	say(Story.HuntStart[2])
	say(Story.HuntStart[3])

	local escaped = Instance.new("BindableEvent")
	local hasFrontKey = false

	-- Ha elkap: nem halsz meg, csak "felébredsz" az előszobában.
	companion.onCatch = function(player: Player)
		player:SetAttribute("SafeUntil", os.clock() + Config.CaughtSafeTime)
		playSound(Config.Sounds.Caught, map.folder)
		storyEvent:FireClient(player, "Effect", "Caught")
		companion:calm(3)
		task.delay(0.5, function()
			local character = player.Character
			if character then
				character:PivotTo(map.spawn.CFrame + Vector3.new(0, 4, 0))
			end
			remark(Story.Caught, player)
		end)
	end

	-- Kis zenedobozok: megnyugtatják, de utána egy ideig nem húzhatók fel újra.
	for _, calmBox in map.calmBoxes do
		local prompt = getPrompt(calmBox)
		prompt.Enabled = true
		track(prompt.Triggered:Connect(function()
			prompt.Enabled = false
			companion:calm(Config.CalmDuration)
			remark(Story.Calmed)
			local chime = playSound(Config.Sounds.MusicBox, calmBox, false)
			task.delay(Config.CalmDuration, function()
				if chime then
					chime:Stop()
				end
			end)
			task.delay(Config.CalmCooldown, function()
				if hunting then
					prompt.Enabled = true
				end
			end)
		end))
	end

	-- Raktárkulcs a párna alatt
	setObjective(Story.Objectives.StorageKey)
	local pillowPrompt = getPrompt(map.pillow)
	pillowPrompt.Enabled = true
	track(pillowPrompt.Triggered:Connect(function()
		pillowPrompt.Enabled = false
		hasStorageKey = true
		playSound(Config.Sounds.Pickup, map.folder)
		remark(Story.GotStorageKey)
		setObjective(Story.Objectives.Storage)
	end))

	-- Bejárati kulcs a raktárban
	local keyPrompt = getPrompt(map.frontDoorKey)
	keyPrompt.Enabled = true
	track(keyPrompt.Triggered:Connect(function()
		hasFrontKey = true
		playSound(Config.Sounds.Pickup, map.folder)
		map.frontDoorKey:Destroy()
		remark(Story.GotFrontKey)
		setObjective(Story.Objectives.Escape)
	end))

	-- Bejárati ajtó
	local frontPrompt = getPrompt(map.frontDoor)
	frontPrompt.Enabled = true
	track(frontPrompt.Triggered:Connect(function(player)
		if hasFrontKey then
			frontPrompt.Enabled = false
			escaped:Fire()
		else
			remark(Story.FrontDoorLocked, player)
		end
	end))

	companion:calm(Config.HuntGraceTime) -- rövid előny, utána magától üldözni kezd

	escaped.Event:Wait()
	escaped:Destroy()

	---------------------------------------------------------------------------
	-- Vége
	---------------------------------------------------------------------------

	hunting = false
	companion.onCatch = nil
	companion:setMode("Idle")
	map.frontDoor.CanCollide = false
	map.frontDoor.Transparency = 1
	setObjective("")
	storyEvent:FireAllClients("Ending", Story.Ending)
	task.wait(Config.EndingTime)

	for _, connection in connections do
		connection:Disconnect()
	end
	for _, sound in sounds do
		sound:Destroy()
	end
end

return Director
