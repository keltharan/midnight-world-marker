local ignoreMods = {
    LSHIFT = true, RSHIFT = true,
    LCTRL  = true, RCTRL  = true,
    LALT   = true, RALT   = true,
    -- Dragonflight+ also sends:
    SHIFT  = true, CTRL   = true, ALT = true,
    META   = true, RMETA  = true, LMETA = true,
}

local f = CreateFrame("Frame", "MWM_KeyCapturePopup", UIParent, "BackdropTemplate")
f:SetSize(400, 200)
f:SetFrameStrata("TOOLTIP")       -- highest possible
f:SetFrameLevel(9999)            -- above all AceGUI
f:SetPoint("CENTER")
f:EnableMouse(true)
f:Hide()

f:SetBackdrop({
    bgFile  = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
f.title:SetPoint("TOP", 0, -20)
f.title:SetText("Press a key now")

f.desc = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.desc:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
f.desc:SetText("Keyboard or Mouse. ESC to cancel.")

f.keyText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
f.keyText:SetPoint("CENTER", 0, 0)
f.keyText:SetText("")

f.bg = f:CreateTexture(nil, "BACKGROUND")
f.bg:SetAllPoints()
f.bg:SetColorTexture(0, 0, 0, 0.6)

local callback = nil

local mouseMap = {
    LeftButton   = "BUTTON1",
    RightButton  = "BUTTON2",
    MiddleButton = "BUTTON3",
    Button4      = "BUTTON4",
    Button5      = "BUTTON5",
}

local function NormalizeKey(key)
    if mouseMap[key] then
        return mouseMap[key]
    end
    return key:upper()
end

function f:StartCapture(cb)
    callback = cb
    f.keyText:SetText("")
    f:Show()
end

-- Capture KEY DOWN
f:SetPropagateKeyboardInput(false)
f:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:Hide()
        if callback then callback(nil) end
        return
    end

    if ignoreMods[key] then
        return
    end

    local n = NormalizeKey(key)
    f.keyText:SetText(n)

    C_Timer.After(0.1, function()
        f:Hide()
        if callback then callback(n) end
    end)
end)

-- Capture mouse
f:SetScript("OnMouseDown", function(self, btn)
    local n = NormalizeKey(btn)
    f.keyText:SetText(n)

    C_Timer.After(0.1, function()
        f:Hide()
        if callback then callback(n) end
    end)
end)
