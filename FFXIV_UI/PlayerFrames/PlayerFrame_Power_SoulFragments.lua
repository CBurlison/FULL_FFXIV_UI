--print("FFXIV UI Player Power (Soul Fragments) loaded")


local f = PlayerFrame_Power_SoulFragments

local bar = f.bar

local tex = bar:GetStatusBarTexture()
tex:SetDrawLayer("ARTWORK", 0)
tex:SetTexCoord(0.5, 1, 0, 1)

local outlineFrame = f.outlineFrame
outlineFrame:SetFrameLevel(f:GetFrameLevel() + 5)

local text = outlineFrame.text

local powerLabel = outlineFrame.powerLabel


local soulFragmentTexture = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Health"
local function Update()

    if select(2, UnitClass("player")) ~= "DEMONHUNTER" then
        f:Hide()
        return
    else
        f:Show()
    end

    local powerType = SPELL_POWER_SOUL_SHARDS
    local power = UnitPower("player", powerType)
    local maxPower = UnitPowerMax("player", powerType)

    bar:SetMinMaxValues(0, maxPower)
    bar:SetValue(power)
    bar:SetStatusBarTexture(soulFragmentTexture)

    local tex = bar:GetStatusBarTexture()
    tex:SetDrawLayer("ARTWORK", 0)
    tex:SetTexCoord(0.5, 1, 0, 1)

    text:SetText(power)
end


f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_POWER_UPDATE")
f:RegisterEvent("UNIT_MAXPOWER")
f:RegisterEvent("UNIT_DISPLAYPOWER")

f:SetScript("OnEvent", function(_, event, unit, powerType)
    if unit == "player" and (not powerType or powerType == SPELL_POWER_SOUL_SHARDS) then
        Update()
    end
end)

Update()
