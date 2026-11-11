-- Frissítő a Roblox Studio parancssorához (Command Bar).
-- Letölti a GitHubról a legfrissebb szkripteket, és kicseréli őket a megnyitott pályában,
-- így nem kell minden változtatás után újra letölteni és megnyitni a pályafájlt.
--
-- Nem ezt a fájlt kell bemásolni, hanem a README-ben lévő egysoros parancsot:
-- az tölti le és futtatja mindig ennek a fájlnak a legújabb változatát.

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local REPO = "Silvertune/Silvertune"
local BRANCH = "claude/eager-fermi-ru4zch"
local BUNDLE_PATH = "Silvertune.bundle.json"

if RunService:IsRunning() then
	error("Előbb állítsd le a játékot (Stop), és utána futtasd újra a frissítést.")
end

local function fetch(path: string): string
	local response = HttpService:RequestAsync({
		Url = string.format("https://api.github.com/repos/%s/contents/%s?ref=%s", REPO, path, BRANCH),
		Method = "GET",
		Headers = { Accept = "application/vnd.github.raw" },
	})
	if not response.Success then
		error(string.format("A letöltés nem sikerült (%d): %s", response.StatusCode, path))
	end
	return response.Body
end

local bundle = HttpService:JSONDecode(fetch(BUNDLE_PATH))
local count = 0

for _, mount in bundle.mounts do
	-- Megkeressük (vagy létrehozzuk) a helyet, ahová a szkriptek kerülnek.
	local parent: Instance = game:GetService(mount.services[1])
	for i = 2, #mount.services do
		local child = parent:FindFirstChild(mount.services[i])
		if not child then
			child = Instance.new(mount.services[i])
			child.Parent = parent
		end
		parent = child
	end

	local folder = parent:FindFirstChild(mount.folder)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = mount.folder
		folder.Parent = parent
	end

	-- A régi szkripteket töröljük, hogy az átnevezett vagy megszűnt fájlok ne maradjanak ott.
	folder:ClearAllChildren()
	for _, item in mount.scripts do
		local scriptInstance = Instance.new(item.class)
		scriptInstance.Name = item.name
		scriptInstance.Source = item.source
		scriptInstance.Parent = folder
		count += 1
	end
end

print(string.format("Silvertune frissítve: %d szkript (%s). Mehet a Play!", count, bundle.builtAt))
