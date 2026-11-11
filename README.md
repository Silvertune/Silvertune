# Silvertune

Rövid, anime hangulatú co-op horror Robloxra (1–4 játékos, kb. 10–15 perc).

Egy kedves lány, Lumi vendégül lát a házában. Teát főztök, megkeresitek a plüsseit,
felhúzod az ezüst zenedobozát. Lumi addig kedves, amíg szól a dallam. Amikor elhallgat,
ki kell jutnod a házból.

## Kipróbálás (telepítés nélkül)

1. Telepítsd a [Roblox Studiót](https://create.roblox.com/), és jelentkezz be.
2. Töltsd le a repóból a `Silvertune.rbxlx` fájlt, és nyisd meg Studióban.
3. Nyomd meg a **Play** gombot (F5).

A ház indításkor épül fel, ezért szerkesztő nézetben üres a pálya.

## Frissítés újraletöltés nélkül

Ha a pálya már nyitva van Studióban, a legfrissebb szkripteket egy paranccsal be lehet húzni.
Állítsd le a játékot, kattints alul a parancssorba (Command Bar), illeszd be ezt az egy sort, és nyomj Entert:

```lua
local h=game:GetService("HttpService") h.HttpEnabled=true loadstring(h:RequestAsync({Url="https://api.github.com/repos/Silvertune/Silvertune/contents/tools/studio_update.luau?ref=claude/eager-fermi-ru4zch",Headers={Accept="application/vnd.github.raw"}}).Body)()
```

Az Output ablakban a „Silvertune frissítve" sor jelzi, hogy sikerült. Legközelebb elég a parancssorban
a felfelé nyíl és az Enter. A pályát érdemes elmenteni (Ctrl+S), hogy a frissített állapot megmaradjon.

## Az első fejezet menete

| # | Rész | Mit csinál a játékos |
|---|------|----------------------|
| 1 | Érkezés | Lumi köszönt az előszobában |
| 2 | Teázás | 3 csésze összeszedése, lerakás a konyhaasztalra |
| 3 | Plüssök | 4 plüss megkeresése; közben jönnek az első furcsaságok |
| 4 | Zenedoboz | A zenedoboz felhúzása, mellette egy korábbi vendég cetlije |
| 5 | Szökés | A dallam elhallgat, Lumi üldöz: kulcs a párna alól, raktár, bejárati kulcs, ajtó |

Az üldözés alatt a kis zenedobozok felhúzása pár másodpercre megnyugtatja Lumit.
Ha elkap, nem halsz meg, hanem „felébredsz" az előszobában.

## Mi hol van

| Fájl | Mire való |
|------|-----------|
| `src/shared/Config.luau` | Sebességek, időzítések, Lumi kinézete, hangok |
| `src/shared/Story.luau` | Az összes párbeszéd és felirat |
| `src/server/MapBuilder.luau` | A ház felépítése dobozokból |
| `src/server/Companion.luau` | Lumi mozgása: követés, üldözés, útkeresés |
| `src/server/Director.luau` | A fejezet története lépésről lépésre |
| `src/server/Main.server.luau` | Indítás és a fejezet újraindítása |
| `src/client/Main.client.luau` | Képernyőn megjelenő felület és effektek |

## Ami még helykitöltő

- **Lumi kinézete:** dobozokból épített ezüst haj, masni és szoknya. A `Config.luau`-ban adhatsz meg helyette haj-, arc- és ruha-azonosítókat a Roblox katalógusból (ekkor a `BuiltInLook` legyen `false`).
- **Hangok:** nincs beállítva egy sem. A `Config.luau` `Sounds` részébe kerülnek az azonosítók.
- **A ház:** a bútorok és díszek egyszerű dobozokból állnak, később Studióban lecserélhetők rendes modellekre.

## Szerkesztés után

Ha módosítasz a `src/` mappában, a pályafájlt így frissítheted:

```
python3 tools/build_place.py
```

Aki Rojo-t használ, annak a `default.project.json` ugyanezt a felépítést adja.
