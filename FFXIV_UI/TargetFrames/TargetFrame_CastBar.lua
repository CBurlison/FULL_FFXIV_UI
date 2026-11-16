--print("FFXIV UI Target Cast Bar with Interrupt GIF loaded")

local NORMAL_OUTLINE_COLOR      = { 0.822, 0.629, 0.225 }
local INTERRUPT_OUTLINE_COLOR   = { 1.0, 0.2, 0.2 }

local INTERRUPT_GIF_COLOR       = { 1, 0.7, 0.3 }


local castBar = FFTargetCastBar
castBar:SetMinMaxValues(0, 1)


local bg = castBar.bg


local outlineFrame = castBar.outlineFrame
outlineFrame:SetFrameLevel(castBar:GetFrameLevel() + 5)

local staticOutline = outlineFrame.staticOutline
staticOutline:ClearAllPoints()
staticOutline:SetPoint("CENTER", castBar, "CENTER", 0, 2)
staticOutline:SetSize(castBar:GetWidth() * 3, castBar:GetHeight())

local textFrame = castBar.textFrame
textFrame:SetFrameLevel(outlineFrame:GetFrameLevel() + 1)

local text = textFrame.text


local gifFrame = castBar.gifFrame
gifFrame:SetFrameLevel(castBar:GetFrameLevel() + 20)

local gifTexture = gifFrame.gifTexture
textFrame:SetFrameLevel(gifFrame:GetFrameLevel() + 5)

local anchor = FFXIV_UI_Anchors.TargetCast
castBar:SetParent(anchor)
castBar:ClearAllPoints()
castBar:SetPoint("CENTER", anchor, "CENTER", 0, -15)

local frames = {}
local FRAME_COUNT = 14 

for i = 1, FRAME_COUNT do
    frames[i] =
        ("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Interruptable\\Layer %d.tga"):format(i)
end




local gifTicker
local frameIndex = 1
local gifPlaying = false

local function StartGif()
    if gifPlaying or not frames[1] then return end
    gifPlaying = true
    frameIndex = 1

    gifTexture:SetTexture(frames[1])
    gifTexture:Show()

    gifTicker = C_Timer.NewTicker(0.05, function()
        frameIndex = frameIndex + 1
        if frameIndex > #frames then frameIndex = 1 end
        gifTexture:SetTexture(frames[frameIndex])
    end)
end

local function StopGif()
    gifPlaying = false
    gifTexture:Hide()

    if gifTicker then
        gifTicker:Cancel()
        gifTicker = nil
    end
end

 

local function StopCast()
    castBar:Hide()
    outlineFrame:Hide()
    staticOutline:Hide()
    StopGif()
     
end

local function UpdateCast()

    local name, _, texture, start, endTime, isTradeSkill, castID, notInterruptible, spellid = UnitCastingInfo("target");
           

    if name then
        castBar:SetTimerDuration(UnitCastingDuration("target"), 0, 0)

        castBar:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, CreateColor(1.0, 1.0, 1.0, 1), CreateColor(1.0, 1.0, 1.0, 1))

        staticOutline:SetVertexColorFromBoolean(notInterruptible,  CreateColor(0.822, 0.629, 0.225, 1), CreateColor(1.0, 0.2, 0.2, 1))

        gifTexture:SetVertexColorFromBoolean(notInterruptible, CreateColor(0.0, 0.0, 0.0, 0), CreateColor(1, 0.7, 0.3, 1))
     
        bg:SetVertexColorFromBoolean(notInterruptible, CreateColor(0.259, 0.188, 0.024, 1, 1), CreateColor(0.23, 0.10, 0.0, 1))

        if not UnitCanAttack("player", "target") then
            gifTexture:SetVertexColor(0.0, 0.0, 0.0, 0)
            staticOutline:SetVertexColor(unpack(NORMAL_OUTLINE_COLOR))
            castBar:SetStatusBarColor(1, 1, 1)
            bg:SetVertexColor(0.259, 0.188, 0.024, 1)
        end 

        text:SetText(name)
        castBar:Show()
        outlineFrame:Show()
        staticOutline:Show()
        return
    end


    name, _, texture, start, endTime, isTradeSkill, notInterruptible, spellid = UnitChannelInfo("target");
         
 
    if name then
        castBar:SetTimerDuration(UnitChannelDuration("target"), 0, 1)

        castBar:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, CreateColor(1.0, 1.0, 1.0, 1), CreateColor(1.0, 1.0, 1.0, 1))

        staticOutline:SetVertexColorFromBoolean(notInterruptible,  CreateColor(0.822, 0.629, 0.225, 1), CreateColor(1.0, 0.2, 0.2, 1))

        gifTexture:SetVertexColorFromBoolean(notInterruptible, CreateColor(0.0, 0.0, 0.0, 0), CreateColor(1, 0.7, 0.3, 1))

        bg:SetVertexColorFromBoolean(notInterruptible, CreateColor(0.259, 0.188, 0.024, 1), CreateColor(0.23, 0.10, 0.0, 1))

        if not UnitCanAttack("player", "target") then
            gifTexture:SetVertexColor(0.0, 0.0, 0.0, 0)
            staticOutline:SetVertexColor(unpack(NORMAL_OUTLINE_COLOR))
            castBar:SetStatusBarColor(1, 1, 1)
            bg:SetVertexColor(0.259, 0.188, 0.024, 1)
        end 

        text:SetText(name)
        castBar:Show()
        outlineFrame:Show()
        staticOutline:Show()
        return
    end

    StopCast()

end

local function OnCastStart()
    UpdateCast()    
    StartGif()

end



local function OnChannelStart(unit)
       UpdateCast()    
       StartGif()
end


local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_SPELLCAST_START")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
f:RegisterEvent("UNIT_SPELLCAST_STOP")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
f:RegisterEvent("UNIT_SPELLCAST_FAILED")
f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
f:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

f:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        UpdateCast()
        
        if castBar:IsShown() then
            StartGif()
        else
            StopGif()
        end
        return
    end

    if unit == "target" then
        if event == "UNIT_SPELLCAST_CHANNEL_START" then
            C_Timer.After(0.01, OnCastStart)
        elseif event == "UNIT_SPELLCAST_START" then
            OnCastStart()
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_FAILED" then
            StopCast()
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            UpdateCast()
        end
    end
end)




castBar:SetScript("OnUpdate", UpdateCast)
