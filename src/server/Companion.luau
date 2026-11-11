--!nonstrict
-- A lány (NPC): létrehozás, animáció és mozgás.
-- Négy állapota van:
--   Idle   - áll egy helyben
--   Follow - kedvesen követi a legközelebbi játékost
--   Hunt   - üldözi a legközelebbi játékost, és elkapja, ha odaér
--   Calm   - megnyugodott (zenedoboz), egy ideig áll, aztán újra Hunt

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- A Roblox alap R15 animációi (minden játékban használhatók)
local IDLE_ANIMATION = "rbxassetid://507766388"
local WALK_ANIMATION = "rbxassetid://507777826"

local STEP_INTERVAL = 0.15

local Companion = {}
Companion.__index = Companion

-- Ha a rendes karakter valamiért nem tölthető be, egy egyszerű dobozfigura is megteszi.
local function buildFallbackRig(): Model
	local settings = Config.Companion
	local model = Instance.new("Model")

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 4, 1.5)
	root.Color = settings.DressColor
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = settings.SkinColor
	head.CanCollide = false
	head.Massless = true
	head.CFrame = root.CFrame * CFrame.new(0, 2.8, 0)
	head.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = root

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 1
	humanoid.Parent = model

	model.PrimaryPart = root
	return model
end

-- Egy kis doboz hozzáhegesztve a karakter egyik testrészéhez (haj, masni, szoknya).
local function attach(model: Model, base: BasePart, name: string, size: Vector3, offset: Vector3, color: Color3)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = base.CFrame * CFrame.new(offset)
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = part
	weld.Parent = part
end

-- Beépített kinézet: ezüst haj két copffal, masni és szoknya, katalógus nélkül.
-- A karakter -Z irányba néz, tehát a +Z a háta.
local function decorate(model: Model)
	local settings = Config.Companion
	local hair = settings.HairColor
	local accent = settings.AccentColor

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local s = head.Size
		attach(model, head, "HairTop", Vector3.new(s.X + 0.3, 0.4, s.Z + 0.3), Vector3.new(0, s.Y / 2 + 0.05, 0), hair)
		attach(model, head, "HairBack", Vector3.new(s.X + 0.3, s.Y + 1.4, 0.3), Vector3.new(0, -0.55, s.Z / 2 + 0.1), hair)
		-- A frufru csak a homlok tetejét takarja, hogy a szeme látsszon.
		attach(model, head, "HairBangs", Vector3.new(s.X + 0.3, 0.16, 0.2), Vector3.new(0, s.Y / 2 - 0.07, -(s.Z / 2 + 0.05)), hair)
		for _, side in { -1, 1 } do
			attach(model, head, "HairSide", Vector3.new(0.2, s.Y + 0.3, s.Z * 0.6), Vector3.new(side * (s.X / 2 + 0.05), -0.05, s.Z * 0.25), hair)
			attach(model, head, "HairTie", Vector3.new(0.5, 0.22, 0.5), Vector3.new(side * (s.X / 2 + 0.4), 0.15, 0.2), accent)
			attach(model, head, "Ponytail", Vector3.new(0.45, 2.3, 0.45), Vector3.new(side * (s.X / 2 + 0.4), -1.05, 0.2), hair)
			attach(model, head, "BowLoop", Vector3.new(0.55, 0.4, 0.2), Vector3.new(side * 0.35, s.Y / 2 + 0.45, 0), accent)
		end
		attach(model, head, "BowKnot", Vector3.new(0.25, 0.3, 0.25), Vector3.new(0, s.Y / 2 + 0.42, 0), accent)
	end

	local hips = model:FindFirstChild("LowerTorso")
	if hips and hips:IsA("BasePart") then
		local s = hips.Size
		attach(model, hips, "Skirt", Vector3.new(s.X + 0.5, 0.9, s.Z + 0.5), Vector3.new(0, -0.3, 0), settings.DressColor)
		attach(model, hips, "SkirtHem", Vector3.new(s.X + 0.7, 0.2, s.Z + 0.7), Vector3.new(0, -0.8, 0), Color3.fromRGB(255, 255, 255))
	end

	local chest = model:FindFirstChild("UpperTorso")
	if chest and chest:IsA("BasePart") then
		local s = chest.Size
		for _, side in { -1, 1 } do
			attach(model, chest, "RibbonLoop", Vector3.new(0.4, 0.3, 0.12), Vector3.new(side * 0.28, s.Y / 2 - 0.3, -(s.Z / 2 + 0.04)), accent)
		end
		attach(model, chest, "RibbonKnot", Vector3.new(0.18, 0.22, 0.16), Vector3.new(0, s.Y / 2 - 0.3, -(s.Z / 2 + 0.05)), accent)
	end
end

local function buildRig(): Model
	local settings = Config.Companion

	local description = Instance.new("HumanoidDescription")
	description.HeadColor = settings.SkinColor
	description.LeftArmColor = settings.SkinColor
	description.RightArmColor = settings.SkinColor
	description.TorsoColor = settings.DressColor
	description.LeftLegColor = settings.LegColor
	description.RightLegColor = settings.LegColor
	description.HairAccessory = settings.HairAccessory
	description.Face = settings.Face
	description.Shirt = settings.Shirt
	description.Pants = settings.Pants

	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if ok and result and result:FindFirstChildOfClass("Humanoid") and result:FindFirstChild("HumanoidRootPart") then
		return result
	end

	warn("[Companion] A karakter betöltése nem sikerült, dobozfigurát használok:", result)
	return buildFallbackRig()
end

function Companion.new(startCFrame: CFrame, parent: Instance)
	local self = setmetatable({}, Companion)

	local model = buildRig()
	model.Name = Config.Companion.Name

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	humanoid.DisplayName = Config.Companion.Name

	-- A gyári "Animate" szkript csak játékos-karakteren fut, itt magunk animálunk.
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end

	if Config.Companion.BuiltInLook then
		decorate(model)
	end

	model:PivotTo(startCFrame)
	model.Parent = parent

	-- A szerver mozgassa, ne egy közeli játékos gépe (különben csalható lenne).
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	self.model = model
	self.humanoid = humanoid
	self.root = root
	self.mode = "Idle"
	self.calmUntil = 0
	self.alive = true
	self.onCatch = nil :: ((Player) -> ())?
	self.path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false,
	})

	self:_setupAnimations()

	task.spawn(function()
		while self.alive do
			self:_step()
			task.wait(STEP_INTERVAL)
		end
	end)

	return self
end

function Companion:_setupAnimations()
	local humanoid: Humanoid = self.humanoid
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local function load(id: string, priority: Enum.AnimationPriority): AnimationTrack?
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return (animator :: Animator):LoadAnimation(animation)
		end)
		if ok and track then
			track.Priority = priority
			track.Looped = true
			return track
		end
		return nil
	end

	local idle = load(IDLE_ANIMATION, Enum.AnimationPriority.Idle)
	local walk = load(WALK_ANIMATION, Enum.AnimationPriority.Movement)
	if idle then
		idle:Play()
	end

	humanoid.Running:Connect(function(speed)
		if not walk then
			return
		end
		if speed > 0.5 then
			if not walk.IsPlaying then
				walk:Play(0.2)
			end
		elseif walk.IsPlaying then
			walk:Stop(0.2)
		end
	end)
end

function Companion:setMode(mode: string)
	self.mode = mode
	if mode == "Follow" then
		self.humanoid.WalkSpeed = Config.FollowSpeed
	elseif mode == "Hunt" then
		self.humanoid.WalkSpeed = Config.HuntSpeed
	else
		self:_stop()
	end
end

-- Megnyugtatás: ennyi másodpercig áll, utána magától újra üldöz.
function Companion:calm(seconds: number)
	self.calmUntil = os.clock() + seconds
	self:setMode("Calm")
end

function Companion:destroy()
	self.alive = false
	self.model:Destroy()
end

function Companion:_stop()
	self.humanoid:MoveTo(self.root.Position)
end

-- A legközelebbi élő, nem védett játékos.
function Companion:_nearestPlayer(): (Player?, Vector3?, number)
	local bestPlayer, bestPosition, bestDistance = nil, nil, math.huge
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		local safeUntil = player:GetAttribute("SafeUntil")
		local isSafe = self.mode == "Hunt" and typeof(safeUntil) == "number" and safeUntil > now
		if playerRoot and playerRoot:IsA("BasePart") and playerHumanoid and playerHumanoid.Health > 0 and not isSafe then
			local distance = (playerRoot.Position - self.root.Position).Magnitude
			if distance < bestDistance then
				bestPlayer, bestPosition, bestDistance = player, playerRoot.Position, distance
			end
		end
	end
	return bestPlayer, bestPosition, bestDistance
end

-- Útvonalkeresés a falak körül: mindig a következő útpont felé indul.
function Companion:_moveToward(goal: Vector3)
	local path: Path = self.path
	local origin = self.root.Position
	local ok = pcall(function()
		path:ComputeAsync(origin, goal)
	end)

	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for i = 2, #waypoints do
			if (waypoints[i].Position - origin).Magnitude > 3 then
				self.humanoid:MoveTo(waypoints[i].Position)
				return
			end
		end
	end

	-- Nincs útvonal (vagy már majdnem ott van): egyenesen a cél felé.
	self.humanoid:MoveTo(goal)
end

function Companion:_step()
	if self.mode == "Idle" then
		return
	end

	if self.mode == "Calm" then
		if os.clock() >= self.calmUntil then
			self:setMode("Hunt")
		end
		return
	end

	local player, position, distance = self:_nearestPlayer()
	if not player or not position then
		self:_stop()
		return
	end

	if self.mode == "Follow" then
		if distance <= Config.FollowDistance then
			self:_stop()
			return
		end
	elseif self.mode == "Hunt" then
		if distance <= Config.CatchDistance then
			if self.onCatch then
				self.onCatch(player)
			end
			return
		end
	end

	self:_moveToward(position)
end

return Companion
