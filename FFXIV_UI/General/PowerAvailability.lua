local addonName, addonEnv = ...

function addonEnv.HasPlayerPower(powerType)
	if type(powerType) ~= "number" or type(UnitPowerMax) ~= "function" then
		return false
	end

	local ok, maximum = pcall(UnitPowerMax, "player", powerType)
	if not ok or (issecretvalue and issecretvalue(maximum)) then
		return false
	end

	return type(maximum) == "number" and maximum > 0
end

local WAIT_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"PLAYER_SPECIALIZATION_CHANGED",
	"PLAYER_TALENT_UPDATE",
	"TRAIT_CONFIG_UPDATED",
	"SPELLS_CHANGED",
	"UNIT_MAXPOWER",
}

-- Runs callback once the player's max power for powerType is readable. On a fresh login
-- the max can still read 0 when files load, so this waits for events instead of giving up.
function addonEnv.OnPlayerPowerReady(powerType, callback)
	if addonEnv.HasPlayerPower(powerType) then
		callback()
		return
	end

	local waiter = CreateFrame("Frame")
	for _, event in ipairs(WAIT_EVENTS) do
		waiter:RegisterEvent(event)
	end

	waiter:SetScript("OnEvent", function(self)
		if not addonEnv.HasPlayerPower(powerType) then
			return
		end

		self:UnregisterAllEvents()
		self:SetScript("OnEvent", nil)
		callback()
	end)
end
