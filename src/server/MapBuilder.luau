--!strict
-- Felépíti a házat egyszerű dobozokból ("greybox"). Ez helykitöltő pálya:
-- arra való, hogy a játékmenet kipróbálható legyen, később Studióban
-- lecserélhető rendes modellekre.
--
-- Alaprajz felülnézetből (x: nyugat -> kelet, z: észak -> dél), 80 x 60 stud:
--
--   +-----------+-----------+-----------+  z = -30
--   | Hálószoba |  Raktár   | Zeneszoba |
--   +---  ------+--[ajtó]---+------  ---+  z = -5
--   |              Folyosó              |
--   +---  ------+--       --+------  ---+  z = 5
--   |  Nappali  |  Előszoba |   Konyha  |
--   +-----------+-[bejárat]-+-----------+  z = 30
--  x = -40     -12          12          40

local Workspace = game:GetService("Workspace")

local MapBuilder = {}

local WALL_HEIGHT = 10
local WALL_THICKNESS = 1

local WALL_COLOR = Color3.fromRGB(214, 180, 178)
local FLOOR_COLOR = Color3.fromRGB(170, 120, 90)
local FURNITURE_COLOR = Color3.fromRGB(215, 190, 170)
local LAMP_COLOR = Color3.fromRGB(255, 220, 170)

export type Lamp = { part: Part, light: PointLight }

export type Map = {
	folder: Folder,
	spawn: SpawnLocation,
	companionStart: CFrame,
	lamps: { Lamp },
	cups: { Part },
	plushies: { Part },
	kitchenTable: Part,
	musicBox: Part,
	note: Part,
	pillow: Part,
	storageDoor: Part,
	frontDoorKey: Part,
	frontDoor: Part,
	calmBoxes: { Part },
}

local function box(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Tengelyirányú fal két pont között (vagy x1 == x2, vagy z1 == z2).
local function wall(parent: Instance, x1: number, z1: number, x2: number, z2: number)
	local size
	if z1 == z2 then
		size = Vector3.new(math.abs(x2 - x1), WALL_HEIGHT, WALL_THICKNESS)
	else
		size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, math.abs(z2 - z1))
	end
	local position = Vector3.new((x1 + x2) / 2, WALL_HEIGHT / 2, (z1 + z2) / 2)
	box(parent, "Wall", size, position, WALL_COLOR)
end

-- "E" gombos interakció egy tárgyon. Alapból kikapcsolva; a Director kapcsolja be,
-- amikor a történetben sorra kerül.
local function addPrompt(part: Part, actionText: string, objectText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = part
	return prompt
end

local function lamp(parent: Instance, x: number, z: number): Lamp
	local part = box(parent, "Lamp", Vector3.new(2, 0.5, 2), Vector3.new(x, WALL_HEIGHT - 1.5, z), LAMP_COLOR, Enum.Material.Neon)
	part.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = 24
	light.Brightness = 0.45
	light.Color = LAMP_COLOR
	light.Parent = part
	return { part = part, light = light }
end

local function plushie(parent: Instance, position: Vector3, color: Color3): Part
	local body = box(parent, "Plushie", Vector3.new(1.5, 2, 1.5), position, color, Enum.Material.Fabric)
	local head = box(body, "Head", Vector3.new(1.2, 1.2, 1.2), position + Vector3.new(0, 1.5, 0), color, Enum.Material.Fabric)
	head.CanCollide = false
	return body
end

function MapBuilder.build(): Map
	local folder = Instance.new("Folder")
	folder.Name = "Map"

	local structure = Instance.new("Folder")
	structure.Name = "Structure"
	structure.Parent = folder

	-- Talaj, padló, plafon
	box(structure, "Ground", Vector3.new(400, 1, 400), Vector3.new(0, -1.5, 0), Color3.fromRGB(30, 45, 35), Enum.Material.Grass)
	box(structure, "Floor", Vector3.new(80, 1, 60), Vector3.new(0, -0.5, 0), FLOOR_COLOR, Enum.Material.WoodPlanks)
	box(structure, "Ceiling", Vector3.new(80, 1, 60), Vector3.new(0, WALL_HEIGHT + 0.5, 0), WALL_COLOR)

	-- Külső falak (a déli falon a bejárati ajtó helye kimarad)
	wall(structure, -40, -30, 40, -30)
	wall(structure, -40, -30, -40, 30)
	wall(structure, 40, -30, 40, 30)
	wall(structure, -40, 30, -4, 30)
	wall(structure, 4, 30, 40, 30)

	-- A folyosó északi fala (ajtónyílások: hálószoba, raktár, zeneszoba)
	wall(structure, -40, -5, -30, -5)
	wall(structure, -22, -5, -4, -5)
	wall(structure, 4, -5, 22, -5)
	wall(structure, 30, -5, 40, -5)

	-- A folyosó déli fala (ajtónyílások: nappali, előszoba, konyha)
	wall(structure, -40, 5, -30, 5)
	wall(structure, -22, 5, -7, 5)
	wall(structure, 7, 5, 22, 5)
	wall(structure, 30, 5, 40, 5)

	-- Szobák közti válaszfalak
	wall(structure, -12, -30, -12, -5)
	wall(structure, 12, -30, 12, -5)
	wall(structure, -12, 5, -12, 30)
	wall(structure, 12, 5, 12, 30)

	-- Lámpák: szobánként egy, a folyosón kettő
	local lamps = {
		lamp(structure, 0, 17),
		lamp(structure, -26, 17),
		lamp(structure, 26, 17),
		lamp(structure, -26, -17),
		lamp(structure, 0, -17),
		lamp(structure, 26, -17),
		lamp(structure, -20, 0),
		lamp(structure, 20, 0),
	}

	-- Kezdőpont az előszobában
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, -0.4, 22)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder

	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = folder

	-- Bútorok
	box(props, "KitchenCounter", Vector3.new(3, 3, 20), Vector3.new(37.5, 1.5, 17), FURNITURE_COLOR)
	local kitchenTable = box(props, "KitchenTable", Vector3.new(6, 3, 4), Vector3.new(24, 1.5, 18), FURNITURE_COLOR, Enum.Material.Wood)
	addPrompt(kitchenTable, "Set the table", "Kitchen table")

	box(props, "Sofa", Vector3.new(4, 3, 10), Vector3.new(-36, 1.5, 18), Color3.fromRGB(200, 150, 170), Enum.Material.Fabric)
	box(props, "CoffeeTable", Vector3.new(6, 2, 4), Vector3.new(-26, 1, 18), FURNITURE_COLOR, Enum.Material.Wood)

	box(props, "Bed", Vector3.new(8, 2, 12), Vector3.new(-30, 1, -22), Color3.fromRGB(255, 200, 215), Enum.Material.Fabric)
	box(props, "Nightstand", Vector3.new(3, 2, 3), Vector3.new(-37, 1, -27), FURNITURE_COLOR, Enum.Material.Wood)
	local pillow = box(props, "Pillow", Vector3.new(5, 0.8, 2.5), Vector3.new(-30, 2.4, -26.5), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	addPrompt(pillow, "Look under", "Pillow")

	-- Teáscsészék
	local cups = {}
	for _, position in { Vector3.new(37, 3.5, 12), Vector3.new(-26, 2.5, 18), Vector3.new(-37, 2.5, -27) } do
		local cup = box(props, "Teacup", Vector3.new(0.8, 1, 0.8), position, Color3.fromRGB(255, 255, 255))
		addPrompt(cup, "Take", "Teacup")
		table.insert(cups, cup)
	end

	-- Plüssök
	local plushies = {}
	local plushieSpots = {
		{ Vector3.new(-37, 1, 27), Color3.fromRGB(255, 180, 200) },
		{ Vector3.new(15, 1, 27), Color3.fromRGB(180, 210, 255) },
		{ Vector3.new(-15, 1, -8), Color3.fromRGB(255, 240, 170) },
		{ Vector3.new(38, 1, 0), Color3.fromRGB(200, 255, 200) },
	}
	for _, spot in plushieSpots do
		local plush = plushie(props, spot[1], spot[2])
		addPrompt(plush, "Pick up", "Plushie")
		table.insert(plushies, plush)
	end

	-- Zeneszoba: talapzat, ezüst zenedoboz, és a (még láthatatlan) cetli
	box(props, "Pedestal", Vector3.new(3, 3, 3), Vector3.new(26, 1.5, -22), Color3.fromRGB(240, 240, 245))
	local musicBox = box(props, "MusicBox", Vector3.new(2, 1, 1.5), Vector3.new(26, 3.5, -22), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	addPrompt(musicBox, "Wind up", "Silver music box")

	local note = box(props, "Note", Vector3.new(1.5, 0.1, 2), Vector3.new(22, 0.05, -20), Color3.fromRGB(240, 235, 210))
	note.Transparency = 1
	note.CanCollide = false
	addPrompt(note, "Read", "Crumpled note")

	-- Raktár: zárt ajtó, mögötte névcédulás plüssök és a bejárati kulcs
	local storageDoor = box(props, "StorageDoor", Vector3.new(8, WALL_HEIGHT, 1), Vector3.new(0, WALL_HEIGHT / 2, -5), Color3.fromRGB(120, 80, 60), Enum.Material.Wood)
	addPrompt(storageDoor, "Open", "Storage room")

	local pastel = {
		Color3.fromRGB(255, 180, 200),
		Color3.fromRGB(180, 210, 255),
		Color3.fromRGB(255, 240, 170),
		Color3.fromRGB(200, 255, 200),
		Color3.fromRGB(220, 190, 255),
	}
	local index = 0
	for x = -9, 9, 4.5 do
		for z = -22, -10, 4 do
			if not (x == 0 and z == -22) then
				index += 1
				plushie(props, Vector3.new(x, 1, z), pastel[index % #pastel + 1])
			end
		end
	end

	box(props, "Shelf", Vector3.new(4, 1, 2), Vector3.new(0, 0.5, -27), FURNITURE_COLOR, Enum.Material.Wood)
	local frontDoorKey = box(props, "FrontDoorKey", Vector3.new(0.4, 0.4, 1.2), Vector3.new(0, 1.3, -27), Color3.fromRGB(255, 215, 90), Enum.Material.Neon)
	addPrompt(frontDoorKey, "Take", "Front door key")

	-- Bejárati ajtó
	local frontDoor = box(props, "FrontDoor", Vector3.new(8, WALL_HEIGHT, 1), Vector3.new(0, WALL_HEIGHT / 2, 30), Color3.fromRGB(120, 80, 60), Enum.Material.Wood)
	addPrompt(frontDoor, "Open", "Front door")

	-- Kis zenedobozok, amikkel az üldözés alatt meg lehet nyugtatni
	local calmBoxes = {}
	for _, position in { Vector3.new(-38, 0, 0), Vector3.new(10, 0, 28) } do
		box(props, "Stool", Vector3.new(2, 2, 2), position + Vector3.new(0, 1, 0), FURNITURE_COLOR, Enum.Material.Wood)
		local calmBox = box(props, "SmallMusicBox", Vector3.new(1.2, 0.8, 1), position + Vector3.new(0, 2.4, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
		addPrompt(calmBox, "Wind up", "Small music box")
		table.insert(calmBoxes, calmBox)
	end

	folder.Parent = Workspace

	return {
		folder = folder,
		spawn = spawn,
		companionStart = CFrame.lookAt(Vector3.new(0, 3, 10), Vector3.new(0, 3, 22)),
		lamps = lamps,
		cups = cups,
		plushies = plushies,
		kitchenTable = kitchenTable,
		musicBox = musicBox,
		note = note,
		pillow = pillow,
		storageDoor = storageDoor,
		frontDoorKey = frontDoorKey,
		frontDoor = frontDoor,
		calmBoxes = calmBoxes,
	}
end

return MapBuilder
