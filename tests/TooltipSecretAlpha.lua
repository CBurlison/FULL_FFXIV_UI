local secret = {secret = true}
function issecretvalue(value) return value == secret end
function hooksecurefunc() end
function CreateFrame()
    return setmetatable({}, {__index = function() return function() end end})
end

local namespace = {}
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", namespace)
local Tooltips = namespace.Tooltips

local region = {alpha = secret, point = {"TOPLEFT"}}
function region:GetPoint() return "TOPLEFT", nil, "TOPLEFT", 0, 0 end
function region:GetAlpha() return self.alpha end
function region:SetAlpha(value)
    assert(not issecretvalue(value), "secret alpha must not be reapplied")
    self.alpha = value
end

local saved = {}
Tooltips.SaveNativeRegion(saved, region)
assert(type(saved[region].alpha) == "number" and saved[region].alpha == 1,
    "secret alpha must be replaced with a plain opacity before it is stored")
assert(not issecretvalue(saved[region].alpha))
print("PASS: secret native alpha is stored as plain opacity without comparing it")

region.alpha = 0.5
local plain = {}
Tooltips.SaveNativeRegion(plain, region)
assert(plain[region].alpha == 0.5, "plain alpha must still be preserved")
print("PASS: plain native alpha is preserved when saved")
