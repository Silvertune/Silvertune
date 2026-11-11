--!strict
-- Felépíti a házat egyszerű elemekből. Minden bútor és dísz sima dobozokból áll,
-- hogy asset nélkül is otthonos legyen; később Studióban lecserélhető rendes modellekre.
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
local DOOR_HEIGHT = 8

-- Színpaletta: meleg, pasztell "cuki szoba" hangulat
local WALL_COLOR = Color3.fromRGB(214, 180, 178)
local TRIM_COLOR = Color3.fromRGB(246, 236, 230)
local CEILING_COLOR = Color3.fromRGB(232, 216, 208)
local FLOOR_COLOR = Color3.fromRGB(170, 120, 90)
local WOOD_COLOR = Color3.fromRGB(150, 105, 80)
local DARK_WOOD_COLOR = Color3.fromRGB(105, 70, 55)
local CREAM_COLOR = Color3.fromRGB(240, 228, 215)
local PINK_COLOR = Color3.fromRGB(235, 150, 175)
local SOFT_PINK_COLOR = Color3.fromRGB(250, 200, 215)
local LILAC_COLOR = Color3.fromRGB(200, 180, 235)
local MINT_COLOR = Color3.fromRGB(185, 225, 205)
local SILVER_COLOR = Color3.fromRGB(200, 205, 215)
local NIGHT_COLOR = Color3.fromRGB(22, 28, 58)
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

-- Dísz: ugyanaz, mint a box, de nem lehet nekimenni (szőnyeg, kép, függöny...).
local function deco(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
	local part = box(parent, name, size, position, color, material)
	part.CanCollide = false
	return part
end

-- Tengelyirányú fal két pont között (vagy x1 == x2, vagy z1 == z2), szegélyléccel.
local function wall(parent: Instance, x1: number, z1: number, x2: number, z2: number)
	local length = math.abs(x2 - x1) + math.abs(z2 - z1)
	local alongX = z1 == z2
	local center = Vector3.new((x1 + x2) / 2, 0, (z1 + z2) / 2)

	local function slab(name: string, height: number, thickness: number, y: number, color: Color3): Part
		local size = if alongX then Vector3.new(length, height, thickness) else Vector3.new(thickness, height, length)
		return box(parent, name, size, center + Vector3.new(0, y, 0), color)
	end

	slab("Wall", WALL_HEIGHT, WALL_THICKNESS, WALL_HEIGHT / 2, WALL_COLOR)
	slab("Baseboard", 0.6, WALL_THICKNESS + 0.2, 0.3, TRIM_COLOR).CanCollide = false
end

-- Ajtónyílás fölötti falrész, hogy az ajtók ne érjenek plafonig.
local function lintel(parent: Instance, x: number, z: number, width: number)
	local height = WALL_HEIGHT - DOOR_HEIGHT
	box(parent, "Lintel", Vector3.new(width, height, WALL_THICKNESS), Vector3.new(x, DOOR_HEIGHT + height / 2, z), WALL_COLOR)
	deco(parent, "DoorTrim", Vector3.new(width, 0.3, WALL_THICKNESS + 0.2), Vector3.new(x, DOOR_HEIGHT + 0.15, z), TRIM_COLOR)
end

-- Ablak a fal belső oldalán: keret, éjszakai üveg és két függöny.
-- facing: merre néz a szoba felé ("x+" = kelet felé, "z-" = észak felé, stb.)
local function window(parent: Instance, position: Vector3, facing: string, width: number, height: number)
	local alongX = facing == "z+" or facing == "z-"
	local sign = if facing == "x+" or facing == "z+" then 1 else -1
	local out = if alongX then Vector3.new(0, 0, sign) else Vector3.new(sign, 0, 0)
	local side = if alongX then Vector3.new(1, 0, 0) else Vector3.new(0, 0, 1)

	local function panel(name: string, w: number, h: number, depth: number, offset: Vector3, color: Color3, material: Enum.Material?)
		local size = if alongX then Vector3.new(w, h, depth) else Vector3.new(depth, h, w)
		deco(parent, name, size, position + offset, color, material)
	end

	panel("WindowFrame", width + 0.6, height + 0.6, 0.15, out * 0.08, TRIM_COLOR)
	panel("WindowGlass", width, height, 0.15, out * 0.16, NIGHT_COLOR, Enum.Material.Glass)
	panel("WindowBar", 0.2, height, 0.15, out * 0.24, TRIM_COLOR)
	panel("WindowBar", width, 0.2, 0.15, out * 0.24, TRIM_COLOR)
	for _, direction in { -1, 1 } do
		panel("Curtain", 1.2, height + 1.2, 0.25, out * 0.4 + side * direction * (width / 2 + 0.3), SOFT_PINK_COLOR, Enum.Material.Fabric)
	end
end

-- Kép a falon: keret és egy pasztell "festmény".
local function picture(parent: Instance, position: Vector3, facing: string, color: Color3)
	local alongX = facing == "z+" or facing == "z-"
	local sign = if facing == "x+" or facing == "z+" then 1 else -1
	local out = if alongX then Vector3.new(0, 0, sign) else Vector3.new(sign, 0, 0)
	local function panel(name: string, w: number, h: number, offset: Vector3, panelColor: Color3)
		local size = if alongX then Vector3.new(w, h, 0.15) else Vector3.new(0.15, h, w)
		deco(parent, name, size, position + offset, panelColor)
	end
	panel("PictureFrame", 3, 2.4, out * 0.08, DARK_WOOD_COLOR)
	panel("Picture", 2.5, 1.9, out * 0.14, color)
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

local function addLight(part: Part, range: number, brightness: number): Lamp
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness
	light.Color = LAMP_COLOR
	light.Parent = part
	return { part = part, light = light }
end

-- Mennyezeti függőlámpa
local function ceilingLamp(parent: Instance, x: number, z: number): Lamp
	deco(parent, "LampCord", Vector3.new(0.15, 1.3, 0.15), Vector3.new(x, WALL_HEIGHT - 0.65, z), DARK_WOOD_COLOR)
	local shade = deco(parent, "Lamp", Vector3.new(2, 0.6, 2), Vector3.new(x, WALL_HEIGHT - 1.5, z), LAMP_COLOR, Enum.Material.Neon)
	return addLight(shade, 24, 0.45)
end

local function plushie(parent: Instance, position: Vector3, color: Color3): Part
	local body = box(parent, "Plushie", Vector3.new(1.5, 2, 1.5), position, color, Enum.Material.Fabric)
	local head = deco(body, "Head", Vector3.new(1.3, 1.2, 1.3), position + Vector3.new(0, 1.5, 0), color, Enum.Material.Fabric)
	-- fülek és szemek, hogy plüssnek látsszon, ne kockának
	for _, direction in { -1, 1 } do
		deco(head, "Ear", Vector3.new(0.4, 0.5, 0.3), position + Vector3.new(direction * 0.45, 2.3, 0), color, Enum.Material.Fabric)
		deco(head, "Eye", Vector3.new(0.18, 0.18, 0.1), position + Vector3.new(direction * 0.3, 1.6, 0.66), Color3.fromRGB(30, 25, 30))
	end
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
	box(structure, "Ceiling", Vector3.new(80, 1, 60), Vector3.new(0, WALL_HEIGHT + 0.5, 0), CEILING_COLOR)

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

	-- Ajtónyílások fölötti falrészek
	lintel(structure, -26, -5, 8)
	lintel(structure, 0, -5, 8)
	lintel(structure, 26, -5, 8)
	lintel(structure, -26, 5, 8)
	lintel(structure, 0, 5, 14)
	lintel(structure, 26, 5, 8)
	lintel(structure, 0, 30, 8)

	-- Mennyezeti lámpák: szobánként egy, a folyosón kettő.
	-- A sorrend számít: a Director a 3. (konyhai) lámpát villogtatja meg először.
	local lamps = {
		ceilingLamp(structure, 0, 17),
		ceilingLamp(structure, -26, 17),
		ceilingLamp(structure, 26, 17),
		ceilingLamp(structure, -26, -17),
		ceilingLamp(structure, 0, -17),
		ceilingLamp(structure, 26, -17),
		ceilingLamp(structure, -20, 0),
		ceilingLamp(structure, 20, 0),
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

	---------------------------------------------------------------------------
	-- Előszoba
	---------------------------------------------------------------------------

	deco(props, "WelcomeMat", Vector3.new(5, 0.1, 3), Vector3.new(0, 0.05, 27), PINK_COLOR, Enum.Material.Fabric)
	box(props, "ShoeCabinet", Vector3.new(5, 2, 1.5), Vector3.new(-8.5, 1, 28.5), WOOD_COLOR, Enum.Material.Wood)
	deco(props, "Vase", Vector3.new(0.7, 1.2, 0.7), Vector3.new(-8.5, 2.6, 28.5), MINT_COLOR)
	window(props, Vector3.new(-8, 6.5, 29.5), "z-", 3, 2.5)
	picture(props, Vector3.new(-11.5, 5.5, 14), "x+", SOFT_PINK_COLOR)
	picture(props, Vector3.new(11.5, 5.5, 14), "x-", MINT_COLOR)

	---------------------------------------------------------------------------
	-- Folyosó
	---------------------------------------------------------------------------

	deco(props, "RunnerRug", Vector3.new(64, 0.1, 4), Vector3.new(0, 0.05, 0), PINK_COLOR, Enum.Material.Fabric)
	deco(props, "RunnerRugCenter", Vector3.new(63, 0.1, 3), Vector3.new(0, 0.07, 0), SOFT_PINK_COLOR, Enum.Material.Fabric)
	picture(props, Vector3.new(-14, 5.5, -4.5), "z+", LILAC_COLOR)
	picture(props, Vector3.new(13, 5.5, -4.5), "z+", SOFT_PINK_COLOR)
	picture(props, Vector3.new(-15, 5.5, 4.5), "z-", MINT_COLOR)
	picture(props, Vector3.new(15, 5.5, 4.5), "z-", LILAC_COLOR)

	---------------------------------------------------------------------------
	-- Nappali
	---------------------------------------------------------------------------

	deco(props, "LivingRug", Vector3.new(14, 0.1, 12), Vector3.new(-26, 0.05, 18), SOFT_PINK_COLOR, Enum.Material.Fabric)
	box(props, "SofaSeat", Vector3.new(4, 1.5, 10), Vector3.new(-36.25, 0.75, 18), PINK_COLOR, Enum.Material.Fabric)
	box(props, "SofaBack", Vector3.new(1, 3.5, 10), Vector3.new(-38.75, 1.75, 18), PINK_COLOR, Enum.Material.Fabric)
	box(props, "SofaArm", Vector3.new(5, 2.5, 1), Vector3.new(-36.75, 1.25, 12.5), PINK_COLOR, Enum.Material.Fabric)
	box(props, "SofaArm", Vector3.new(5, 2.5, 1), Vector3.new(-36.75, 1.25, 23.5), PINK_COLOR, Enum.Material.Fabric)
	deco(props, "Cushion", Vector3.new(1.4, 1.4, 1.4), Vector3.new(-37, 2.2, 15), CREAM_COLOR, Enum.Material.Fabric)
	deco(props, "Cushion", Vector3.new(1.4, 1.4, 1.4), Vector3.new(-37, 2.2, 21), LILAC_COLOR, Enum.Material.Fabric)
	box(props, "CoffeeTable", Vector3.new(6, 2, 4), Vector3.new(-26, 1, 18), WOOD_COLOR, Enum.Material.Wood)
	window(props, Vector3.new(-39.5, 6.8, 18), "x+", 6, 3)

	box(props, "Bookshelf", Vector3.new(8, 8, 1.5), Vector3.new(-17, 4, 6.5), DARK_WOOD_COLOR, Enum.Material.Wood)
	for row, color in { PINK_COLOR, MINT_COLOR, LILAC_COLOR } do
		deco(props, "Books", Vector3.new(7, 1.3, 0.3), Vector3.new(-17, row * 2.3 - 0.3, 7.3), color)
	end

	deco(props, "FloorLampPole", Vector3.new(0.3, 6, 0.3), Vector3.new(-37, 3, 8), DARK_WOOD_COLOR)
	local floorLamp = deco(props, "FloorLamp", Vector3.new(1.6, 1.4, 1.6), Vector3.new(-37, 6.5, 8), LAMP_COLOR, Enum.Material.Neon)
	table.insert(lamps, addLight(floorLamp, 12, 0.4))

	---------------------------------------------------------------------------
	-- Konyha
	---------------------------------------------------------------------------

	deco(props, "KitchenTiles", Vector3.new(27, 0.06, 24), Vector3.new(26, 0.03, 17.5), CREAM_COLOR)
	box(props, "KitchenCounter", Vector3.new(3, 3, 20), Vector3.new(37.5, 1.5, 17), CREAM_COLOR)
	box(props, "Countertop", Vector3.new(3.4, 0.3, 20.4), Vector3.new(37.5, 3.15, 17), DARK_WOOD_COLOR, Enum.Material.Wood)
	deco(props, "UpperCabinets", Vector3.new(1.5, 2.5, 20), Vector3.new(38.75, 7.5, 17), CREAM_COLOR)
	deco(props, "Kettle", Vector3.new(0.9, 1, 0.9), Vector3.new(37.5, 3.8, 20), PINK_COLOR)
	box(props, "Fridge", Vector3.new(3, 7, 2.4), Vector3.new(37.5, 3.5, 28.25), MINT_COLOR)
	deco(props, "FridgeHandle", Vector3.new(0.15, 2, 0.2), Vector3.new(35.9, 4.5, 27.5), SILVER_COLOR, Enum.Material.Metal)

	local kitchenTable = box(props, "KitchenTable", Vector3.new(6, 3, 4), Vector3.new(24, 1.5, 18), WOOD_COLOR, Enum.Material.Wood)
	addPrompt(kitchenTable, "Set the table", "Kitchen table")
	deco(props, "Tablecloth", Vector3.new(6.3, 0.1, 2.4), Vector3.new(24, 3.05, 18), SOFT_PINK_COLOR, Enum.Material.Fabric)
	for _, z in { 14.5, 21.5 } do
		box(props, "ChairSeat", Vector3.new(2, 2, 2), Vector3.new(24, 1, z), WOOD_COLOR, Enum.Material.Wood)
		local backZ = if z < 18 then z - 0.8 else z + 0.8
		box(props, "ChairBack", Vector3.new(2, 2.5, 0.4), Vector3.new(24, 3.25, backZ), WOOD_COLOR, Enum.Material.Wood)
	end
	window(props, Vector3.new(26, 6.5, 29.5), "z-", 6, 3)

	---------------------------------------------------------------------------
	-- Hálószoba
	---------------------------------------------------------------------------

	deco(props, "BedroomRug", Vector3.new(10, 0.1, 8), Vector3.new(-27, 0.05, -11), LILAC_COLOR, Enum.Material.Fabric)
	box(props, "Bed", Vector3.new(8, 2, 12), Vector3.new(-30, 1, -22), CREAM_COLOR, Enum.Material.Fabric)
	box(props, "Headboard", Vector3.new(8, 4.5, 0.6), Vector3.new(-30, 2.25, -28.9), DARK_WOOD_COLOR, Enum.Material.Wood)
	deco(props, "Blanket", Vector3.new(8.2, 0.4, 7), Vector3.new(-30, 2.2, -19.5), PINK_COLOR, Enum.Material.Fabric)
	box(props, "Nightstand", Vector3.new(3, 2, 3), Vector3.new(-37, 1, -27), WOOD_COLOR, Enum.Material.Wood)
	local pillow = box(props, "Pillow", Vector3.new(5, 0.8, 2.5), Vector3.new(-30, 2.4, -26.5), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	addPrompt(pillow, "Look under", "Pillow")
	box(props, "Wardrobe", Vector3.new(2.5, 8, 6), Vector3.new(-14, 4, -20), WOOD_COLOR, Enum.Material.Wood)
	deco(props, "WardrobeGap", Vector3.new(0.1, 7.4, 0.15), Vector3.new(-15.3, 4, -20), DARK_WOOD_COLOR)
	window(props, Vector3.new(-39.5, 6.5, -14), "x+", 6, 3)

	---------------------------------------------------------------------------
	-- Zeneszoba
	---------------------------------------------------------------------------

	deco(props, "MusicRug", Vector3.new(12, 0.1, 12), Vector3.new(26, 0.05, -20), Color3.fromRGB(150, 70, 90), Enum.Material.Fabric)
	box(props, "Pedestal", Vector3.new(3, 3, 3), Vector3.new(26, 1.5, -22), TRIM_COLOR)
	deco(props, "PedestalCloth", Vector3.new(3.3, 0.1, 3.3), Vector3.new(26, 3.03, -22), PINK_COLOR, Enum.Material.Fabric)
	local musicBox = box(props, "MusicBox", Vector3.new(2, 1, 1.5), Vector3.new(26, 3.55, -22), SILVER_COLOR, Enum.Material.Metal)
	addPrompt(musicBox, "Wind up", "Silver music box")
	deco(musicBox, "Crank", Vector3.new(0.2, 0.2, 0.7), Vector3.new(27.1, 3.6, -22), Color3.fromRGB(255, 215, 90), Enum.Material.Metal)

	box(props, "Piano", Vector3.new(8, 5, 2), Vector3.new(34, 2.5, -28.4), Color3.fromRGB(40, 32, 36))
	deco(props, "PianoKeys", Vector3.new(7.6, 0.3, 1.2), Vector3.new(34, 2.9, -26.9), Color3.fromRGB(250, 250, 250))
	box(props, "PianoBench", Vector3.new(4, 1.5, 1.5), Vector3.new(34, 0.75, -24.5), DARK_WOOD_COLOR, Enum.Material.Wood)
	window(props, Vector3.new(39.5, 6.5, -17), "x-", 6, 3)
	picture(props, Vector3.new(20, 5.5, -29.5), "z+", SILVER_COLOR)

	local note = deco(props, "Note", Vector3.new(1.5, 0.1, 2), Vector3.new(21.5, 0.16, -18), Color3.fromRGB(240, 235, 210))
	note.Transparency = 1
	addPrompt(note, "Read", "Crumpled note")

	---------------------------------------------------------------------------
	-- Tárgyak, amiket össze kell szedni
	---------------------------------------------------------------------------

	local cups = {}
	for _, position in { Vector3.new(37, 3.8, 12), Vector3.new(-26, 2.5, 18), Vector3.new(-37, 2.5, -27) } do
		local cup = box(props, "Teacup", Vector3.new(0.8, 1, 0.8), position, Color3.fromRGB(255, 255, 255))
		deco(cup, "Rim", Vector3.new(0.9, 0.15, 0.9), position + Vector3.new(0, 0.45, 0), PINK_COLOR)
		addPrompt(cup, "Take", "Teacup")
		table.insert(cups, cup)
	end

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

	---------------------------------------------------------------------------
	-- Raktár: zárt ajtó, mögötte névcédulás plüssök és a bejárati kulcs.
	-- Szándékosan kopár és hideg, hogy elüssön a ház többi részétől.
	---------------------------------------------------------------------------

	local storageDoor = box(props, "StorageDoor", Vector3.new(8, DOOR_HEIGHT, 1), Vector3.new(0, DOOR_HEIGHT / 2, -5), DARK_WOOD_COLOR, Enum.Material.Wood)
	deco(storageDoor, "Knob", Vector3.new(0.4, 0.4, 1.3), Vector3.new(3, 3.8, -5), SILVER_COLOR, Enum.Material.Metal)
	addPrompt(storageDoor, "Open", "Storage room")

	deco(props, "StorageFloor", Vector3.new(23, 0.06, 24), Vector3.new(0, 0.03, -17.5), Color3.fromRGB(95, 95, 105), Enum.Material.Concrete)

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
			index += 1
			local plush = plushie(props, Vector3.new(x, 1, z), pastel[index % #pastel + 1])
			deco(plush, "NameTag", Vector3.new(0.7, 0.4, 0.05), Vector3.new(x, 0.9, z + 0.78), Color3.fromRGB(250, 245, 230))
		end
	end

	box(props, "Shelf", Vector3.new(4, 1, 2), Vector3.new(0, 0.5, -27), DARK_WOOD_COLOR, Enum.Material.Wood)
	local frontDoorKey = box(props, "FrontDoorKey", Vector3.new(0.4, 0.4, 1.2), Vector3.new(0, 1.3, -27), Color3.fromRGB(255, 215, 90), Enum.Material.Neon)
	addPrompt(frontDoorKey, "Take", "Front door key")

	---------------------------------------------------------------------------
	-- Bejárati ajtó és a kis zenedobozok
	---------------------------------------------------------------------------

	local frontDoor = box(props, "FrontDoor", Vector3.new(8, DOOR_HEIGHT, 1), Vector3.new(0, DOOR_HEIGHT / 2, 30), DARK_WOOD_COLOR, Enum.Material.Wood)
	deco(frontDoor, "Knob", Vector3.new(0.4, 0.4, 1.3), Vector3.new(3, 3.8, 30), Color3.fromRGB(255, 215, 90), Enum.Material.Metal)
	addPrompt(frontDoor, "Open", "Front door")

	local calmBoxes = {}
	for _, position in { Vector3.new(-38, 0, 0), Vector3.new(10, 0, 28) } do
		box(props, "Stool", Vector3.new(2, 2, 2), position + Vector3.new(0, 1, 0), WOOD_COLOR, Enum.Material.Wood)
		local calmBox = box(props, "SmallMusicBox", Vector3.new(1.2, 0.8, 1), position + Vector3.new(0, 2.4, 0), SILVER_COLOR, Enum.Material.Metal)
		deco(calmBox, "Crank", Vector3.new(0.15, 0.15, 0.5), position + Vector3.new(0.7, 2.4, 0), Color3.fromRGB(255, 215, 90), Enum.Material.Metal)
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
