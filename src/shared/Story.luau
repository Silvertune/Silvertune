--!strict
-- A fejezet összes szövege. A játék szövege angol (a Roblox közönsége nemzetközi),
-- de itt bármit átírhatsz anélkül, hogy a logikához hozzányúlnál.
-- Minden sor: { beszélő, szöveg }. Üres beszélő = narráció / gondolat.

local Story = {}

Story.Intro = {
	{ "Lumi", "Oh! You're finally here! I've been waiting all day." },
	{ "Lumi", "Come in, come in. Make yourself at home, okay?" },
	{ "Lumi", "I was just about to make tea. Could you find the teacups for me?" },
}

Story.TeaReady = {
	{ "Lumi", "Three cups! Perfect. Put them on the kitchen table, please." },
}

Story.TeaDone = {
	{ "Lumi", "It's so nice to have a guest again." },
	{ "Lumi", "The last one left without even saying goodbye. So rude." },
	{ "Lumi", "Oh no... my plushies are all over the house. Help me find them?" },
}

Story.PlushiesDone = {
	{ "Lumi", "You found them all! They really like you, I can tell." },
	{ "Lumi", "You're staying for dinner, right?" },
	{ "Lumi", "Everyone stays for dinner." },
	{ "Lumi", "...Anyway! My music box is in the music room. Would you wind it up for me?" },
}

Story.MusicBoxWound = {
	{ "Lumi", "Ahh, I love this tune. Don't let it stop, okay?" },
	{ "", "Something is lying on the floor next to the pedestal." },
}

Story.Note = "Day 12.\n\nShe is kind as long as the tune plays.\nWhen it stops - run.\n\nThe front door key is in the room she never lets you enter.\nThe storage key is under her pillow.\n\nThe small music boxes calm her. Not for long."

Story.HuntStart = {
	{ "", "The music box winds down." },
	{ "Lumi", "...It stopped." },
	{ "Lumi", "You let it stop." },
}

-- Egysoros megjegyzések (nem állítják meg a játékot)
Story.StorageLocked = { "Lumi", "Not that room! It's just storage. Nothing to see~" }
Story.StorageLockedHunt = { "", "Locked. The note said the key is under her pillow." }
Story.FrontDoorLocked = { "", "The front door is locked from the inside." }
Story.GotStorageKey = { "", "A small key. This must open the storage room." }
Story.StorageOpened = { "", "Rows of plushies. Each one has a name tag." }
Story.GotFrontKey = { "", "The front door key. Go!" }
Story.Calmed = { "Lumi", "Oh... that tune..." }
Story.Caught = { "Lumi", "You dozed off, silly. You're not leaving already, are you?" }

Story.Objectives = {
	Welcome = "Listen to Lumi",
	Cups = "Find the teacups (%d/%d)",
	Table = "Put the cups on the kitchen table",
	Plushies = "Find Lumi's plushies (%d/%d)",
	MusicBox = "Wind up the music box in the music room",
	Note = "Read the note",
	StorageKey = "Find the storage key",
	Storage = "Unlock the storage room",
	FrontKey = "Find the front door key",
	Escape = "Escape through the front door",
}

-- Üldözés közben Lumi időnként megszólal (véletlenszerűen egy ezek közül).
Story.Taunts = {
	{ "Lumi", "Where are you going? The tea is getting cold." },
	{ "Lumi", "I can hear you, you know." },
	{ "Lumi", "Don't hide. Hiding is rude." },
	{ "Lumi", "Everyone leaves. You won't. Right?" },
	{ "Lumi", "Come back. Please." },
}

Story.Escape = {
	{ "", "The lock clicks. The door swings open into cold night air." },
}

-- A fejezet vége: az ajtó mögött újra az előszoba van.
Story.Cliffhanger = {
	{ "", "...You are standing in the hallway. The front door is closed." },
	{ "", "A new plushie sits on the doormat. The name tag has your name on it." },
	{ "Lumi", "Welcome back! You're just in time for tea." },
}

Story.Ending = {
	Title = "Silvertune",
	Subtitle = "Chapter 1: The Guest - to be continued",
}

return Story
