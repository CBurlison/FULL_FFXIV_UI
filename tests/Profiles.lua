local configs = {
    {key = "PlayerHP", w = 240, h = 86, scale = 1, pos = {"BOTTOM", -120, 55}},
    {key = "TargetHP", w = 670, h = 50, scale = 1, pos = {"TOP", 0, -25}},
}

local function initialize(shared, character, identifier)
    local namespace = {}
    assert(loadfile("FFXIV_UI/General/Profiles.lua"))("FFXIV_UI", namespace)
    namespace.Profiles.Initialize(configs, shared, character, identifier)
    return namespace.Profiles
end

local passed = 0
local function test(name, run)
    run()
    passed = passed + 1
    print("PASS: " .. name)
end

test("fresh character creates standard Default", function()
    local shared, character = {}, {}
    local profiles = initialize(shared, character, "first")
    local state = profiles.GetAnchors().PlayerHP
    assert(profiles.GetActiveName() == "Default")
    assert(state.point == "BOTTOM" and state.relativePoint == "BOTTOM")
    assert(state.x == -120 and state.y == 55 and state.scale == 1)
    assert(state.width == 240 and state.height == 86)
end)

test("custom legacy positions and sizes seed Default", function()
    local character = {PlayerHP = {point = "CENTER", relativePoint = "CENTER", x = 80, y = 40, scale = 1.5, width = 300, height = 100}}
    local profiles = initialize({}, character, "first")
    local state = profiles.GetAnchors().PlayerHP
    assert(state.point == "CENTER" and state.x == 80 and state.y == 40)
    assert(state.scale == 1.5 and state.width == 300 and state.height == 100)
    assert(profiles.GetAnchors().TargetHP.x == 0)
    state.x = 90
    assert(character.PlayerHP.x == 80)
end)

test("scale-only legacy customization seeds Default", function()
    local profiles = initialize({}, {PlayerHP = {scale = 1.2}}, "first")
    assert(profiles.GetAnchors().PlayerHP.scale == 1.2)
    assert(profiles.GetAnchors().PlayerHP.x == -120)
end)

test("later characters do not overwrite Default", function()
    local shared = {}
    initialize(shared, {PlayerHP = {x = 80}}, "first")
    local profiles = initialize(shared, {PlayerHP = {x = 999}}, "second")
    assert(profiles.GetAnchors().PlayerHP.x == 80)
end)

test("new profiles can copy Default or current independently", function()
    local shared = {}
    local profiles = initialize(shared, {}, "first")
    assert(profiles.Add(" Current ", false))
    assert(profiles.GetActiveName() == "Current")
    local state = profiles.GetAnchors().PlayerHP
    state.x = 200
    assert(shared.profiles.Default.anchors.PlayerHP.x == -120)
    assert(profiles.Add("Copy", true))
    assert(profiles.GetAnchors().PlayerHP.x == 200)
    profiles.GetAnchors().PlayerHP.x = 300
    assert(shared.profiles.Current.anchors.PlayerHP.x == 200)
    assert(profiles.Add("Standard", false))
    assert(profiles.GetAnchors().PlayerHP.x == -120)
end)

test("Default is protected and duplicate or blank names fail", function()
    local profiles = initialize({}, {}, "first")
    assert(not profiles.Rename("New Default"))
    assert(not profiles.Delete())
    assert(not profiles.Add("Default", false))
    assert(not profiles.Add("   ", false))
    assert(not profiles.Add(string.rep("x", 65), false))
    assert(profiles.GetActiveName() == "Default")
end)

test("rename preserves layouts and all character selections", function()
    local shared, first, second = {}, {}, {}
    local profiles = initialize(shared, first, "first")
    assert(profiles.Add("Shared", true))
    profiles.GetAnchors().PlayerHP.scale = 1.4
    profiles = initialize(shared, second, "second")
    assert(profiles.Select("Shared"))
    assert(profiles.Rename("Renamed"))
    assert(not shared.profiles.Shared)
    assert(shared.characters.first == "Renamed" and shared.characters.second == "Renamed")
    profiles = initialize(shared, first, "first")
    assert(profiles.GetActiveName() == "Renamed")
    assert(profiles.GetAnchors().PlayerHP.scale == 1.4)
end)

test("delete returns affected characters to Default", function()
    local shared, first, second = {}, {}, {}
    local profiles = initialize(shared, first, "first")
    assert(profiles.Add("Shared", true))
    profiles = initialize(shared, second, "second")
    assert(profiles.Select("Shared"))
    assert(profiles.Delete())
    assert(profiles.GetActiveName() == "Default")
    assert(shared.characters.first == "Default")
    profiles = initialize(shared, first, "first")
    assert(profiles.GetActiveName() == "Default")
    assert(not profiles.Select("Shared"))
end)

test("anchor saves and reset only affect the selected profile", function()
    local shared = {}
    local profiles = initialize(shared, {PlayerHP = {x = 80}}, "first")
    assert(profiles.Add("Layout", true))
    profiles.SaveAnchor("PlayerHP", {point = "CENTER", relativePoint = "CENTER", x = 200, y = 10, scale = 2, width = 400, height = 120})
    assert(profiles.GetAnchors().PlayerHP.width == 400)
    profiles.Reset()
    assert(profiles.GetAnchors().PlayerHP.x == -120)
    assert(profiles.GetAnchors().PlayerHP.scale == 1)
    assert(shared.profiles.Default.anchors.PlayerHP.x == 80)
end)

test("apply restores anchor position scale and dimensions", function()
    local profiles = initialize({}, {PlayerHP = {x = 80, scale = 1.5, width = 300, height = 100}}, "first")
    local anchor = {}
    function anchor:SetScale(value) self.scale = value end
    function anchor:SetSize(width, height) self.width, self.height = width, height end
    function anchor:ClearAllPoints() self.cleared = true end
    function anchor:SetPoint(point, parent, relativePoint, x, y)
        self.point, self.relativePoint, self.x, self.y = point, relativePoint, x, y
    end
    function anchor.RefreshVisual() anchor.refreshed = true end
    profiles.Apply({PlayerHP = anchor})
    assert(anchor.scale == 1.5 and anchor.width == 300 and anchor.height == 100)
    assert(anchor.point == "BOTTOM" and anchor.x == 80 and anchor.y == 55)
    assert(anchor.cleared and anchor.refreshed)
end)

test("new enemy-list anchor falls back for existing profiles and persists independently", function()
    local shared = {profiles = {Default = {anchors = {}}}}
    configs[#configs + 1] = {key = "EnemyList", w = 284, h = 240, scale = 1, pos = {"CENTER", 450, 50}}
    local profiles = initialize(shared, {}, "first")
    local anchor = {}
    function anchor:SetScale(value) self.scale = value end
    function anchor:SetSize(width, height) self.width, self.height = width, height end
    function anchor:ClearAllPoints() end
    function anchor:SetPoint(point, parent, relativePoint, x, y)
        self.point, self.relativePoint, self.x, self.y = point, relativePoint, x, y
    end
    function anchor.RefreshVisual() end
    profiles.Apply({EnemyList = anchor})
    assert(anchor.point == "CENTER" and anchor.x == 450 and anchor.y == 50 and anchor.width == 284)
    profiles.SaveAnchor("EnemyList", {point = "TOPLEFT", relativePoint = "TOPLEFT", x = 30, y = -60, scale = 1.2, width = 284, height = 240})
    assert(profiles.Add("Enemy layout", true))
    profiles.Apply({EnemyList = anchor})
    assert(anchor.x == 30 and anchor.y == -60 and anchor.scale == 1.2)
    profiles.Reset()
    profiles.Apply({EnemyList = anchor})
    assert(anchor.x == 450 and anchor.y == 50 and anchor.scale == 1)
    profiles.Select("Default")
    profiles.Apply({EnemyList = anchor})
    assert(anchor.x == 30 and anchor.y == -60 and anchor.scale == 1.2)
end)

print(string.format("%d profile tests passed", passed))