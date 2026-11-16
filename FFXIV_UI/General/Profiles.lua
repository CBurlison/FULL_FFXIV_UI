local addonName, addonEnv = ...
local Profiles = {}
addonEnv.Profiles = Profiles

local store, character, standardAnchors, characterKey
local anchorFields = {"point", "relativePoint", "x", "y", "scale", "width", "height"}

local function setActive(name)
    character.anchorProfile = name
    if characterKey then store.characters[characterKey] = name end
end

local function copyAnchors(source)
    local copy = {}
    for key, state in pairs(source) do
        copy[key] = {}
        for _, field in ipairs(anchorFields) do
            copy[key][field] = state[field]
        end
    end
    return copy
end

function Profiles.Initialize(configs, sharedSettings, characterSettings, identifier)
    store, character = sharedSettings, characterSettings
    characterKey = identifier
    store.profiles = store.profiles or {}
    store.characters = store.characters or {}
    standardAnchors = {}
    local legacyAnchors = {}
    local customized = false
    for _, config in ipairs(configs) do
        local standard = {
            point = config.pos[1], relativePoint = config.pos[1],
            x = config.pos[2], y = config.pos[3], scale = config.scale,
            width = config.w, height = config.h,
        }
        standardAnchors[config.key] = standard
        local saved = character[config.key]
        local state = {}
        for _, field in ipairs(anchorFields) do
            local value = type(saved) == "table" and saved[field] or nil
            if field == "point" or field == "relativePoint" then
                if type(value) ~= "string" then value = standard[field] end
            elseif type(value) ~= "number" or ((field == "scale" or field == "width" or field == "height") and value <= 0) then
                value = standard[field]
            end
            state[field] = value
            if value ~= standard[field] then customized = true end
        end
        legacyAnchors[config.key] = state
    end
    if not store.profiles.Default then
        store.profiles.Default = {anchors = copyAnchors(customized and legacyAnchors or standardAnchors)}
    end
    local selected = (characterKey and store.characters[characterKey]) or character.anchorProfile
    setActive(store.profiles[selected] and selected or "Default")
end

function Profiles.GetActiveName()
    return character and character.anchorProfile or "Default"
end

function Profiles.GetAnchors()
    if not store then return end
    return store.profiles[Profiles.GetActiveName()].anchors
end

function Profiles.GetNames()
    local names = {}
    if store then
        for name in pairs(store.profiles) do names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

local function validateName(name)
    if type(name) ~= "string" then return nil, "Enter a profile name." end
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return nil, "Enter a profile name." end
    if #name > 64 then return nil, "Profile names must be 64 characters or fewer." end
    if store.profiles[name] then return nil, "A profile with that name already exists." end
    return name
end

function Profiles.Select(name)
    if not store.profiles[name] then return false, "That profile no longer exists." end
    setActive(name)
    return true
end

function Profiles.Add(name, copyCurrent)
    local validName, message = validateName(name)
    if not validName then return false, message end
    local source = copyCurrent and Profiles.GetAnchors() or store.profiles.Default.anchors
    store.profiles[validName] = {anchors = copyAnchors(source)}
    setActive(validName)
    return true
end

function Profiles.Rename(name)
    local active = Profiles.GetActiveName()
    if active == "Default" then return false, "The Default profile cannot be renamed." end
    local validName, message = validateName(name)
    if not validName then return false, message end
    store.profiles[validName] = store.profiles[active]
    store.profiles[active] = nil
    for key, selected in pairs(store.characters) do
        if selected == active then store.characters[key] = validName end
    end
    setActive(validName)
    return true
end

function Profiles.Delete()
    local active = Profiles.GetActiveName()
    if active == "Default" then return false, "The Default profile cannot be deleted." end
    store.profiles[active] = nil
    for key, selected in pairs(store.characters) do
        if selected == active then store.characters[key] = "Default" end
    end
    setActive("Default")
    return true
end

function Profiles.SaveAnchor(key, state)
    local anchors = Profiles.GetAnchors()
    if anchors then anchors[key] = state end
end

function Profiles.Reset()
    store.profiles[Profiles.GetActiveName()].anchors = copyAnchors(standardAnchors)
end

function Profiles.Apply(anchors)
    local savedAnchors = Profiles.GetAnchors()
    if not savedAnchors then return end
    for key, anchor in pairs(anchors) do
        local saved = savedAnchors[key] or standardAnchors[key]
        if saved then
            anchor:SetScale(saved.scale)
            anchor:SetSize(saved.width, saved.height)
            anchor:ClearAllPoints()
            anchor:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
            anchor.RefreshVisual()
        end
    end
end