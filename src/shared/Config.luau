--!strict
-- Minden hangolható érték egy helyen. Ide nyúlj először, ha változtatnál valamin.

local Config = {}

-- A lány (NPC) kinézete. Az asset ID-k a Roblox katalógusból (Marketplace) jönnek:
-- a tárgy oldalának URL-jében lévő szám. 0 / "" = nincs beállítva (sima próbababa).
Config.Companion = {
	Name = "Lumi",
	SkinColor = Color3.fromRGB(255, 226, 210),
	DressColor = Color3.fromRGB(255, 170, 200),
	LegColor = Color3.fromRGB(250, 250, 250),
	HairColor = Color3.fromRGB(236, 240, 255), -- ezüst haj
	AccentColor = Color3.fromRGB(235, 110, 150), -- masni, hajgumi
	BuiltInLook = true, -- dobozokból épített haj, masni és szoknya; false, ha katalógusból öltözteted
	HairAccessory = "", -- pl. "1234567,7654321" (vesszővel több is mehet)
	Face = 0,
	Shirt = 0,
	Pants = 0,
}

-- Mozgás
Config.PlayerWalkSpeed = 14
Config.FollowSpeed = 10 -- amikor kedvesen követ
Config.HuntSpeed = 13 -- amikor üldöz (legyen kicsit lassabb a játékosnál)
Config.FollowDistance = 7 -- ennyire közelít meg követés közben
Config.CatchDistance = 4 -- ennél közelebb elkap

-- Üldözés
Config.HuntGraceTime = 6 -- ennyi mp előnyt kapsz, mielőtt elindul
Config.CalmDuration = 10 -- egy felhúzott zenedoboz ennyi időre megnyugtatja
Config.CalmCooldown = 25 -- ennyi idő múlva húzható fel újra ugyanaz a doboz
Config.CaughtSafeTime = 6 -- elkapás után ennyi ideig nem bánt

Config.FirstPerson = true -- belső nézet (horrorhoz jobb); false = szabad kamera
Config.EndingTime = 14 -- a zárókép hossza, utána újraindul a fejezet

-- Hangok: "rbxassetid://SZÁM" formában. Üresen hagyva egyszerűen nem szól semmi.
-- A Studio Toolbox > Audio fülén találsz ingyenes hangokat.
Config.Sounds = {
	MusicBox = "", -- a zenedoboz dallama (loopolva)
	Ambience = "", -- halk háttérzaj az üldözés alatt
	LightsOut = "", -- amikor lekapcsolnak a fények
	Caught = "", -- amikor elkap
	Pickup = "", -- tárgy felvétele
}

return Config
