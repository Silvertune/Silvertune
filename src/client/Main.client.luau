--!strict
-- Kliens oldal: minden, amit a játékos a képernyőn lát.
-- Feliratok, aktuális cél, cetli, elsötétülés, záróképernyő.
-- A szervertől a "StoryEvent" csatornán kapja, hogy mit mutasson.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local storyEvent = ReplicatedStorage:WaitForChild("StoryEvent") :: RemoteEvent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Belső nézet: a kliensen is beállítjuk, mert a szerverről nem mindig érvényesül.
if Config.FirstPerson then
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

local FONT = Enum.Font.GothamMedium
local PINK = Color3.fromRGB(255, 170, 200)

-------------------------------------------------------------------------------
-- Felület felépítése
-------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "StoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function label(parent: Instance, name: string, textSize: number): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.Font = FONT
	text.TextSize = textSize
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextWrapped = true
	text.Text = ""
	text.Parent = parent
	return text
end

local function roundCorners(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

-- Aktuális cél (felül középen, hogy ne takarja a chat)
local objective = label(gui, "Objective", 22)
objective.AnchorPoint = Vector2.new(0.5, 0)
objective.Position = UDim2.new(0.5, 0, 0, 16)
objective.Size = UDim2.new(0, 0, 0, 34)
objective.AutomaticSize = Enum.AutomaticSize.X
objective.TextWrapped = false
objective.BackgroundColor3 = Color3.fromRGB(20, 16, 22)
objective.BackgroundTransparency = 0.35
objective.Visible = false
roundCorners(objective, 17)
local objectivePadding = Instance.new("UIPadding")
objectivePadding.PaddingLeft = UDim.new(0, 16)
objectivePadding.PaddingRight = UDim.new(0, 16)
objectivePadding.Parent = objective
objective.TextStrokeTransparency = 0.5

-- Párbeszéddoboz (alul középen)
local dialogue = Instance.new("Frame")
dialogue.Name = "Dialogue"
dialogue.AnchorPoint = Vector2.new(0.5, 1)
dialogue.Position = UDim2.new(0.5, 0, 1, -40)
dialogue.Size = UDim2.new(0.7, 0, 0, 110)
dialogue.BackgroundColor3 = Color3.fromRGB(20, 16, 22)
dialogue.BackgroundTransparency = 0.25
dialogue.Visible = false
dialogue.Parent = gui
roundCorners(dialogue, 14)
local dialogueStroke = Instance.new("UIStroke")
dialogueStroke.Color = PINK
dialogueStroke.Thickness = 2
dialogueStroke.Transparency = 0.3
dialogueStroke.Parent = dialogue

local speaker = label(dialogue, "Speaker", 20)
speaker.Position = UDim2.new(0, 18, 0, 10)
speaker.Size = UDim2.new(1, -36, 0, 24)
speaker.TextXAlignment = Enum.TextXAlignment.Left
speaker.TextColor3 = PINK
speaker.Font = Enum.Font.GothamBold

local line = label(dialogue, "Line", 22)
line.Position = UDim2.new(0, 18, 0, 38)
line.Size = UDim2.new(1, -36, 1, -48)
line.TextXAlignment = Enum.TextXAlignment.Left
line.TextYAlignment = Enum.TextYAlignment.Top

-- Cetli (középen, bezárható)
local note = Instance.new("Frame")
note.Name = "Note"
note.AnchorPoint = Vector2.new(0.5, 0.5)
note.Position = UDim2.new(0.5, 0, 0.5, 0)
note.Size = UDim2.new(0, 420, 0, 380)
note.BackgroundColor3 = Color3.fromRGB(240, 235, 210)
note.Visible = false
note.Parent = gui
roundCorners(note, 6)

local noteText = label(note, "Text", 20)
noteText.Position = UDim2.new(0, 24, 0, 24)
noteText.Size = UDim2.new(1, -48, 1, -90)
noteText.TextColor3 = Color3.fromRGB(50, 40, 40)
noteText.Font = Enum.Font.IndieFlower
noteText.TextSize = 24
noteText.TextXAlignment = Enum.TextXAlignment.Left
noteText.TextYAlignment = Enum.TextYAlignment.Top

local closeNote = Instance.new("TextButton")
closeNote.Name = "Close"
closeNote.AnchorPoint = Vector2.new(0.5, 1)
closeNote.Position = UDim2.new(0.5, 0, 1, -16)
closeNote.Size = UDim2.new(0, 140, 0, 40)
closeNote.BackgroundColor3 = Color3.fromRGB(60, 50, 50)
closeNote.TextColor3 = Color3.fromRGB(255, 255, 255)
closeNote.Font = FONT
closeNote.TextSize = 20
closeNote.Text = "Close [X]"
-- Belső nézetben az egér zárolva van; a Modal gomb felszabadítja, amíg a cetli látszik.
closeNote.Modal = true
closeNote.Parent = note
roundCorners(closeNote, 8)
closeNote.Activated:Connect(function()
	note.Visible = false
end)
-- Billentyűvel is bezárható (X vagy Esc helyett Backspace), kontrolleren a B gombbal.
UserInputService.InputBegan:Connect(function(input)
	if not note.Visible then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.X or key == Enum.KeyCode.Backspace or key == Enum.KeyCode.ButtonB then
		note.Visible = false
	end
end)

-- Teljes képernyős réteg: elsötétüléshez, villanáshoz, záróképhez
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.ZIndex = 10
overlay.Parent = gui

local endingTitle = label(overlay, "Title", 48)
endingTitle.AnchorPoint = Vector2.new(0.5, 0.5)
endingTitle.Position = UDim2.new(0.5, 0, 0.45, 0)
endingTitle.Size = UDim2.new(0.8, 0, 0, 60)
endingTitle.Font = Enum.Font.GothamBold
endingTitle.TextTransparency = 1
endingTitle.ZIndex = 11

local endingSubtitle = label(overlay, "Subtitle", 24)
endingSubtitle.AnchorPoint = Vector2.new(0.5, 0.5)
endingSubtitle.Position = UDim2.new(0.5, 0, 0.55, 0)
endingSubtitle.Size = UDim2.new(0.8, 0, 0, 40)
endingSubtitle.TextColor3 = PINK
endingSubtitle.TextTransparency = 1
endingSubtitle.ZIndex = 11

-------------------------------------------------------------------------------
-- Működés
-------------------------------------------------------------------------------

local function tween(instance: Instance, seconds: number, goal: { [string]: any })
	local animation = TweenService:Create(instance, TweenInfo.new(seconds), goal)
	animation:Play()
	return animation
end

-- Minden új sor megszakítja az előzőt: ezzel a számlálóval tudjuk, melyik az aktuális.
local dialogueToken = 0

local function showDialogue(payload: { speaker: string, text: string, duration: number })
	dialogueToken += 1
	local token = dialogueToken

	speaker.Text = payload.speaker
	line.Text = payload.text
	line.Font = if payload.speaker == "" then Enum.Font.GothamMedium else FONT
	line.TextColor3 = if payload.speaker == "" then Color3.fromRGB(200, 200, 210) else Color3.fromRGB(255, 255, 255)
	dialogue.Visible = true

	-- Írógép-effekt: betűnként jelenik meg.
	local length = utf8.len(payload.text) or #payload.text
	line.MaxVisibleGraphemes = 0
	for shown = 1, length do
		if dialogueToken ~= token then
			return
		end
		line.MaxVisibleGraphemes = shown
		task.wait(0.025)
	end
	line.MaxVisibleGraphemes = -1

	task.wait(math.max(payload.duration - length * 0.025, 1))
	if dialogueToken == token then
		dialogue.Visible = false
	end
end

local function resetScreen()
	dialogueToken += 1
	dialogue.Visible = false
	note.Visible = false
	objective.Text = ""
	objective.Visible = false
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	endingTitle.TextTransparency = 1
	endingSubtitle.TextTransparency = 1
end

local effects = {}

-- Elkapott: gyors elsötétülés, majd lassan visszajön a kép.
function effects.Caught()
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	tween(overlay, 0.3, { BackgroundTransparency = 0 })
	task.wait(1.6)
	tween(overlay, 1.2, { BackgroundTransparency = 1 })
end

-- Rövid piros villanás a furcsa pillanatoknál.
function effects.Glitch()
	overlay.BackgroundColor3 = Color3.fromRGB(120, 0, 30)
	overlay.BackgroundTransparency = 0.5
	task.wait(0.08)
	overlay.BackgroundTransparency = 1
	task.wait(0.06)
	overlay.BackgroundTransparency = 0.7
	task.wait(0.05)
	overlay.BackgroundTransparency = 1
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end

storyEvent.OnClientEvent:Connect(function(kind: string, payload: any)
	if kind == "Dialogue" then
		showDialogue(payload)
	elseif kind == "Objective" then
		objective.Text = payload
		objective.Visible = payload ~= ""
	elseif kind == "Note" then
		noteText.Text = payload
		note.Visible = true
	elseif kind == "Effect" then
		local effect = effects[payload]
		if effect then
			effect()
		end
	elseif kind == "Ending" then
		dialogueToken += 1
		dialogue.Visible = false
		note.Visible = false
		endingTitle.Text = payload.Title
		endingSubtitle.Text = payload.Subtitle
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		tween(overlay, 1.5, { BackgroundTransparency = 0 })
		task.wait(1.5)
		tween(endingTitle, 1, { TextTransparency = 0 })
		task.wait(1)
		tween(endingSubtitle, 1, { TextTransparency = 0 })
	elseif kind == "Reset" then
		resetScreen()
	end
end)
