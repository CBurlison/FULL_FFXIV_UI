local addonName, addonEnv = ...

local textureRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\ButtonSkins\\"
local fontRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\"
local pendingButtons = setmetatable({}, { __mode = "k" })
local originalArtVisibility = setmetatable({}, { __mode = "k" })
local originalDividerAlpha = setmetatable({}, { __mode = "k" })
local deferredWork = setmetatable({}, { __mode = "k" })
local pendingHotbarBackgroundHidden
local buttonState = setmetatable({}, { __mode = "k" })

-- Addon state for Blizzard buttons lives here, never on the Blizzard tables themselves.
local function stateFor(button)
	local state = buttonState[button]
	if not state then
		state = { masks = {} }
		buttonState[button] = state
	end
	return state
end
addonEnv.GetButtonSkinState = function(button)
	return buttonState[button]
end

-- Blizzard's action-button update chain is secure. Skin work run from a post-hook inside it
-- taints the rest of that chain (e.g. cooldown updates with secret values), so it runs in a fresh execution.
local function deferOutsideSecureUpdate(owner, tag, callback)
	local tags = deferredWork[owner]
	if not tags then
		tags = {}
		deferredWork[owner] = tags
	end
	if tags[tag] then return end
	tags[tag] = true
	C_Timer.After(0, function()
		tags[tag] = nil
		callback()
	end)
end
addonEnv.DeferOutsideSecureUpdate = deferOutsideSecureUpdate

local skinStyles = {
	General = {
		folder = "General\\",
		iconInset = 0.09,
		iconSize = 46,
		highlightSize = 60,
		-- Texture alpha bounds differ: populated gloss is 58px, well 56px, outline 52px.
		backdropSize = 46 * 58 * 0.92 / 56,
		normalSize = 46 * 58 * 0.92 / 52,
		backdropColor = {1, 1, 1, 1},
		normalTexture = "Normal_clean",
		normalColor = {0.2, 0.2, 0.2, 1},
		hideBackdrop = false,
		hideBorder = true,
		glossOnIcon = true,
	},
	Buffs = {
		folder = "Buffs\\",
		iconInset = 0.07,
		normalSize = 34,
		backdropColor = {0.3, 0.3, 0.3, 1},
		normalTexture = "Outline",
		normalColor = {1, 1, 1, 1},
		hideBackdrop = true,
		hideBorder = true,
	},
	Debuffs = {
		folder = "Debuffs\\",
		iconInset = 0.07,
		normalSize = 34,
		backdropColor = {0.3, 0.3, 0.3, 1},
		normalTexture = "Outline",
		normalColor = {1, 1, 1, 1},
		hideBackdrop = true,
		hideBorder = true,
	},
}

skinStyles.Pet = {}
for key, value in pairs(skinStyles.General) do
	skinStyles.Pet[key] = value
end
skinStyles.Pet.iconSize = 32
skinStyles.Pet.highlightSize = 44
skinStyles.Pet.backdropSize = 30
skinStyles.Pet.normalSize = 32

skinStyles.Stance = {}
for key, value in pairs(skinStyles.General) do
	skinStyles.Stance[key] = value
end
skinStyles.Stance.iconSize = 32
skinStyles.Stance.highlightSize = 44
skinStyles.Stance.backdropSize = 30
skinStyles.Stance.normalSize = 32

local actionButtonPrefixes = {
	"ActionButton",
	"MultiBarBottomLeftButton",
	"MultiBarBottomRightButton",
	"MultiBarRightButton",
	"MultiBarLeftButton",
	"MultiBar5Button",
	"MultiBar6Button",
	"MultiBar7Button",
	"MultiBar8Button",
	"PetActionButton",
	"StanceButton",
	"PossessButton",
	"ExtraActionButton",
}
local actionBars = {
	"MainActionBar",
	"MultiBarBottomLeft",
	"MultiBarBottomRight",
	"MultiBarRight",
	"MultiBarLeft",
	"MultiBar5",
	"MultiBar6",
	"MultiBar7",
	"MultiBar8",
	"PetActionBar",
	"StanceBar",
	"PossessActionBar",
}

local function setArtRegionHidden(region, hidden)
	if not region or not region.SetShown then return end

	if hidden then
		if originalArtVisibility[region] == nil then
			originalArtVisibility[region] = region:IsShown()
		end
		region:Hide()
	else
		local wasShown = originalArtVisibility[region]
		if wasShown ~= nil then
			region:SetShown(wasShown)
			originalArtVisibility[region] = nil
		end
	end
end

local setHotbarBackgroundHidden

local function getIcon(button, regions)
	if regions and regions.Icon then
		return regions.Icon
	end

	local icon = button.icon or button.Icon or button.IconTexture or button.iconTexture
	if icon then
		return icon
	end

	local buttonName = button.GetName and button:GetName()
	if buttonName then
		return _G[buttonName .. "Icon"] or _G[buttonName .. "IconTexture"]
	end
end

local function styleText(region, font, size, color, fontFlags)
	if not region or not region.SetFont then return end

	local _, currentSize, flags = region:GetFont()
	if (issecretvalue and issecretvalue(currentSize)) or type(currentSize) ~= "number" or currentSize <= 0 then
		currentSize = size
	end
	region:SetFont(font, currentSize, fontFlags or flags or "OUTLINE")
	region:SetTextColor(color[1], color[2], color[3], color[4])
	region:SetShadowColor(0, 0, 0, 1)
	region:SetShadowOffset(1, -1)
end

local function addIconMask(button, icon, style, preserveTexCoords)
	local masks = stateFor(button).masks
	local mask = masks[icon]
	if not mask then
		mask = button:CreateMaskTexture()
		mask:SetAllPoints(icon)
		icon:AddMaskTexture(mask)
		masks[icon] = mask
	end
	mask:SetTexture(textureRoot .. style.folder .. "Mask")
	if not preserveTexCoords then
		icon:SetTexCoord(style.iconInset, 1 - style.iconInset, style.iconInset, 1 - style.iconInset)
	end
end

local function addButtonArtwork(button, style, icon)
	local folder = textureRoot .. style.folder
	local state = stateFor(button)
	if not state.backdrop then
		state.backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -5)
		state.backdrop:SetAllPoints(button)
	end
	local backdrop = state.backdrop
	backdrop:SetTexture(folder .. "Backdrop")
	if style.backdropSize then
		backdrop:ClearAllPoints()
		backdrop:SetSize(style.backdropSize, style.backdropSize)
		backdrop:SetPoint("CENTER", icon, "CENTER")
	end
	local backdropColor = style.backdropColor
	backdrop:SetVertexColor(backdropColor[1], backdropColor[2], backdropColor[3], backdropColor[4])
	backdrop:SetShown(not style.hideBackdrop)

	for _, layerName in ipairs({"SlotBackground", "SlotArt"}) do
		local layer = button[layerName]
		if layer and layer.Hide then
			layer:Hide()
		end
	end

	local overlay = state.overlay
	if not overlay then
		overlay = CreateFrame("Frame", nil, button)
		overlay:SetAllPoints(button)
		overlay:SetFrameLevel(button:GetFrameLevel() + 8)
		overlay:EnableMouse(false)
		state.overlay = overlay
	end

	for _, layer in ipairs({"Border", "Gloss"}) do
		local texture = overlay[layer]
		if not texture then
			texture = overlay:CreateTexture(nil, "OVERLAY")
			texture:SetAllPoints(overlay)
			overlay[layer] = texture
		end
		texture:SetTexture(folder .. layer)
		if layer == "Border" then
			texture:SetBlendMode("DISABLE")
		end
	end
	overlay.Gloss:SetAlpha(0.7)
	overlay.Border:SetShown(not style.hideBorder)
	overlay.Gloss:SetShown(not style.hideBorder)

	local nativeNormal = button.GetNormalTexture and button:GetNormalTexture()
	if nativeNormal then
		nativeNormal:SetTexture()
		nativeNormal:Hide()
	end

	local normal = state.normal
	if not normal then
		normal = button:CreateTexture(nil, "ARTWORK")
		state.normal = normal
	end
	normal:SetTexture(folder .. style.normalTexture)
	local normalColor = style.normalColor
	normal:SetVertexColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4])
	normal:SetTexCoord(0, 1, 0, 1)
	local normalAnchor = style.hideBorder and icon or button
	normal:SetSize(style.normalSize, style.normalSize)
	normal:ClearAllPoints()
	normal:SetPoint("CENTER", normalAnchor, "CENTER")
	normal:SetDrawLayer("ARTWORK", 0)
	normal:SetAlpha(1)
	normal:Show()
	if style.glossOnIcon and (type(button.UpdateButtonArt) == "function" or state.style == "Equipment") then
		overlay.Gloss:SetTexture(folder .. "Gloss_clean.tga")
		overlay.Gloss:ClearAllPoints()
		overlay.Gloss:SetAllPoints(icon)
		-- Gloss follows the icon's shown state; refreshed on each skin pass rather than by hooking Show/Hide.
		local iconShown = icon:IsShown()
		overlay.Gloss:SetShown(iconShown)
		normal:SetShown(not iconShown)
	end

	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	if pushed then
		pushed:SetTexture(folder .. "Highlight")
		pushed:SetBlendMode("BLEND")
		if style.highlightSize then
			pushed:ClearAllPoints()
			pushed:SetSize(style.highlightSize, style.highlightSize)
			pushed:SetPoint("CENTER", icon, "CENTER")
			pushed:SetTexCoord(0, 1, 0, 1)
		end
	end

	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	if highlight then
		highlight:SetTexture(folder .. "Highlight")
		highlight:SetBlendMode("ADD")
		if style.highlightSize then
			highlight:ClearAllPoints()
			highlight:SetSize(style.highlightSize, style.highlightSize)
			highlight:SetPoint("CENTER", icon, "CENTER")
			highlight:SetTexCoord(0, 1, 0, 1)
		end
	end

	local checked = button.GetCheckedTexture and button:GetCheckedTexture()
	if checked then
		checked:SetTexture(folder .. "Highlight")
		checked:SetBlendMode("ADD")
		if style.highlightSize then
			checked:ClearAllPoints()
			checked:SetSize(style.highlightSize, style.highlightSize)
			checked:SetPoint("CENTER", icon, "CENTER")
			checked:SetTexCoord(0, 1, 0, 1)
		end
	end
end

local spellCostButtons = setmetatable({}, { __mode = "k" })
local spellCostColors = {
	[Enum.PowerType.Rage] = {1, 0.2, 0.2},
	[Enum.PowerType.Energy] = {1, 0.9, 0.1},
	[Enum.PowerType.Mana] = {0.45, 0.8, 1},
}

local function isReadableNumber(value)
	return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
end

local function updateSpellCost(button)
	local label = spellCostButtons[button]
	if not label then return end
	label:Hide()
	local action = button.action
	if not isReadableNumber(action) or action <= 0 or type(GetActionInfo) ~= "function" then return end

	local infoOK, actionType, spellID = pcall(GetActionInfo, action)
	if not infoOK or (issecretvalue and issecretvalue(actionType)) then return end
	if actionType == "macro" and type(GetMacroSpell) == "function" and isReadableNumber(spellID) then
		local macroOK, macroSpellID = pcall(GetMacroSpell, spellID)
		if not macroOK then return end
		spellID = macroSpellID
	elseif actionType ~= "spell" then
		return
	end
	if not isReadableNumber(spellID) or spellID <= 0 or not C_Spell or not C_Spell.GetSpellPowerCost then return end

	local costsOK, costs = pcall(C_Spell.GetSpellPowerCost, spellID)
	if not costsOK or (issecretvalue and issecretvalue(costs)) or type(costs) ~= "table" then return end
	for _, costInfo in ipairs(costs) do
		if not (issecretvalue and issecretvalue(costInfo)) and type(costInfo) == "table" then
			local powerType, cost, requiredAuraID = costInfo.type, costInfo.cost, costInfo.requiredAuraID
			local color = isReadableNumber(powerType) and spellCostColors[powerType]
			local auraRequirementReadable = not (issecretvalue and issecretvalue(requiredAuraID)) and
				(requiredAuraID == nil or type(requiredAuraID) == "number")
			if color and isReadableNumber(cost) and cost > 0 and auraRequirementReadable then
				local hasRequiredAura = costInfo.hasRequiredAura
				if not (issecretvalue and issecretvalue(hasRequiredAura)) and
					(not requiredAuraID or requiredAuraID == 0 or hasRequiredAura) then
					label:SetTextColor(color[1], color[2], color[3], 1)
					label:SetFormattedText("%.0f", cost)
					label:Show()
					return
				end
			end
		end
	end
end

local function addSpellCostLabel(button, icon, count)
	if type(button.UpdateAction) ~= "function" then return end
	local label = spellCostButtons[button]
	if not label then
		label = stateFor(button).overlay:CreateFontString(nil, "OVERLAY")
		label:SetFont(fontRoot .. "MavenPro-Bold.ttf", 12, "OUTLINE")
		label:SetShadowColor(0, 0, 0, 1)
		label:SetShadowOffset(1, -1)
		label:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 4, -2)
		label:SetJustifyH("RIGHT")
		spellCostButtons[button] = label
	end
	if count then
		count:ClearAllPoints()
		count:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 2, 2)
	end
	updateSpellCost(button)
end

local costEvents = CreateFrame("Frame")
for _, event in ipairs({"ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "SPELLS_CHANGED", "SPELL_UPDATE_CHARGES", "UPDATE_SHAPESHIFT_FORM", "PLAYER_REGEN_ENABLED"}) do
	costEvents:RegisterEvent(event)
end
costEvents:RegisterUnitEvent("UNIT_AURA", "player")
costEvents:RegisterUnitEvent("UNIT_MAXPOWER", "player")
costEvents:SetScript("OnEvent", function()
	for button in pairs(spellCostButtons) do
		updateSpellCost(button)
	end
end)

local function applyButtonSkin(button, regions, styleName, auraSize)
	if not button then return end
	-- Addon-owned aura slots can be created during combat; protected buttons still defer.
	local unprotectedAura = auraSize and (styleName == "Buffs" or styleName == "Debuffs") and not button:IsProtected()
	if InCombatLockdown and InCombatLockdown() and not unprotectedAura then
		pendingButtons[button] = { regions = regions, styleName = styleName, auraSize = auraSize }
		return
	end

	local style = skinStyles[styleName] or skinStyles.General
	local icon = getIcon(button, regions)
	if not icon then return end
	local state = stateFor(button)
	state.style = styleName or "General"

	if styleName == "Equipment" then
		local width = button:GetWidth()
		if not isReadableNumber(width) or width <= 0 then return end
		style = {}
		for key, value in pairs(skinStyles.General) do style[key] = value end
		local scale = width / skinStyles.General.iconSize
		for _, key in ipairs({"iconSize", "highlightSize", "backdropSize", "normalSize"}) do
			style[key] = style[key] * scale
		end
		for _, key in ipairs({"CircleMask", "SquareMask"}) do
			if button[key] then icon:RemoveMaskTexture(button[key]) end
		end
	end

	if style.iconSize then
		icon:ClearAllPoints()
		icon:SetSize(style.iconSize, style.iconSize)
		icon:SetPoint("CENTER", button, "CENTER", 0, (styleName == "Pet" or styleName == "Stance") and 1 or 0)
		icon:SetDrawLayer("BACKGROUND", 0)
		if button.IconMask and icon.RemoveMaskTexture then
			icon:RemoveMaskTexture(button.IconMask)
		end
	end

	addButtonArtwork(button, style, icon)
	addIconMask(button, icon, style)
	if auraSize then state.normal:SetSize(auraSize, auraSize) end

	if styleName == "Pet" and button.AutoCastOverlay then
		button.AutoCastOverlay:ClearAllPoints()
		button.AutoCastOverlay:SetAllPoints(icon)
	end

	local cooldown = (regions and regions.Cooldown) or button.cooldown or button.Cooldown
	if cooldown then
		if style.iconSize then
			cooldown:ClearAllPoints()
			cooldown:SetAllPoints(icon)
		end
		local folder = textureRoot .. style.folder
		if cooldown.SetSwipeTexture then cooldown:SetSwipeTexture(folder .. "Swipe-Circle") end
		if cooldown.SetSwipeColor then cooldown:SetSwipeColor(0, 0, 0, 0.8) end
		if cooldown.SetBlingTexture then cooldown:SetBlingTexture(folder .. "Gloss_clean") end
	end

	local count = (regions and regions.Count) or button.Count or button.count
	styleText(count, fontRoot .. "MavenPro-Bold.ttf", 12, {1, 1, 1, 1})
	if styleName == "General" then
		addSpellCostLabel(button, icon, count)
	end
	local duration = (regions and regions.Duration) or button.Duration or button.duration
	styleText(duration, fontRoot .. "AxisMedium.ttf", 12, {1, 1, 1, 1}, "")

	local hotkey = button.HotKey or button.Hotkey
	styleText(hotkey, fontRoot .. "AxisRegular.ttf", 10, {1, 1, 1, 1}, "")
	state.style = styleName or "General"
end

addonEnv.ApplyButtonSkin = applyButtonSkin

setHotbarBackgroundHidden = function(hidden)
	-- Divider frames inherit action-bar protection; only change their artwork in combat.
	for _, barName in ipairs(actionBars) do
		local bar = _G[barName]
		if bar then
			for _, poolName in ipairs({"HorizontalDividersPool", "VerticalDividersPool"}) do
				local pool = bar[poolName]
				if pool then
					for divider in pool:EnumerateActive() do
						for _, region in ipairs({divider:GetRegions()}) do
							if region:GetObjectType() == "Texture" then
								if hidden then
									if originalDividerAlpha[region] == nil then
										originalDividerAlpha[region] = region:GetAlpha()
									end
									region:SetAlpha(0)
								elseif originalDividerAlpha[region] ~= nil then
									region:SetAlpha(originalDividerAlpha[region])
									originalDividerAlpha[region] = nil
								end
							end
						end
					end
				end
			end
		end
	end

	if InCombatLockdown and InCombatLockdown() then
		pendingHotbarBackgroundHidden = hidden
		return
	end

	local mainArt = _G.MainMenuBarArtFrame
	if mainArt and mainArt.GetRegions then
		for _, region in ipairs({mainArt:GetRegions()}) do
			if region.GetObjectType and region:GetObjectType() == "Texture" then
				setArtRegionHidden(region, hidden)
			end
		end
	end

	for _, barName in ipairs(actionBars) do
		local bar = _G[barName]
		if bar then
			for _, regionName in ipairs({"BorderArt", "Background", "LeftEndCap", "RightEndCap"}) do
				setArtRegionHidden(bar[regionName], hidden)
			end
		end
	end

end

addonEnv.SetHotbarBackgroundHidden = setHotbarBackgroundHidden

local function skinHotbarButtons()
	if InCombatLockdown and InCombatLockdown() then return end

	for _, prefix in ipairs(actionButtonPrefixes) do
		for index = 1, 12 do
			local button = _G[prefix .. index]
			if button then
				applyButtonSkin(button, nil, prefix == "PetActionButton" and "Pet" or prefix == "StanceButton" and "Stance" or "General")
			end
		end
	end

	local zoneSpellButton = ZoneAbilityFrame and ZoneAbilityFrame.SpellButton
	if zoneSpellButton then
		applyButtonSkin(zoneSpellButton, nil, "General")
	end

	setHotbarBackgroundHidden(FFXIV_UI_DB.hideBlizzardHotbarBackground ~= false)
end

local function skinBlizzardAuraFrame(auraFrame, styleName)
	if not auraFrame or type(auraFrame.auraFrames) ~= "table" then return end

	for _, button in ipairs(auraFrame.auraFrames) do
		if not button.isAuraAnchor then
			applyButtonSkin(button, {
				Icon = button.Icon,
				Cooldown = button.Cooldown,
				Count = button.Count,
			}, styleName)
			if button.DebuffBorder then button.DebuffBorder:Hide() end
			if button.TempEnchantBorder then button.TempEnchantBorder:Hide() end
		end
	end
end

local function skinBlizzardAuraFrames()
	skinBlizzardAuraFrame(_G.BuffFrame, "Buffs")
	skinBlizzardAuraFrame(_G.DebuffFrame, "Debuffs")
end

local function refreshAllSkins()
	skinHotbarButtons()
	skinBlizzardAuraFrames()
end

-- Blizzard re-creates and re-shows these elements without telling us, so refresh from events.
-- Deferred to a fresh execution and coalesced so bursts (e.g. login slot updates) run one pass.
local refreshQueued = false
local function queueRefresh()
	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(0, function()
		refreshQueued = false
		refreshAllSkins()
	end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
loader:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
loader:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
loader:RegisterEvent("UPDATE_BINDINGS")
loader:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
loader:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
loader:RegisterUnitEvent("UNIT_AURA", "player")
loader:SetScript("OnEvent", function(_, event, loadedAddon, ...)
	if event == "ADDON_LOADED" and loadedAddon ~= "Blizzard_ActionBar" and loadedAddon ~= "Blizzard_PetActionBar" and loadedAddon ~= "Blizzard_StanceBar" and loadedAddon ~= "Blizzard_OverrideActionBar" then
		if loadedAddon ~= "Blizzard_BuffFrame" then return end
	end

	if event == "PLAYER_REGEN_ENABLED" then
		for button, pending in pairs(pendingButtons) do
			applyButtonSkin(button, pending.regions, pending.styleName, pending.auraSize)
			pendingButtons[button] = nil
		end
		if pendingHotbarBackgroundHidden ~= nil then
			setHotbarBackgroundHidden(pendingHotbarBackgroundHidden)
			pendingHotbarBackgroundHidden = nil
		end
	end

	queueRefresh()
end)
