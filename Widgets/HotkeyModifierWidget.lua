local Type, Version = "HotkeyModifier", 5
local AceGUI = LibStub("AceGUI-3.0")

if AceGUI:GetWidgetVersion(Type) and AceGUI:GetWidgetVersion(Type) >= Version then
    return
end

local modifierList = {
    NONE="None",
    SHIFT="Shift",
    CTRL="Ctrl",
    ALT="Alt",
    SHIFTCTRL="Shift+Ctrl",
    SHIFTALT="Shift+Alt",
    CTRLALT="Ctrl+Alt",
    SHIFTCTRLALT="Shift+Ctrl+Alt",
}

local modifierOrder = {
    "NONE","SHIFT","CTRL","ALT",
    "SHIFTCTRL","SHIFTALT","CTRLALT","SHIFTCTRLALT",
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local widget = {
        type = Type,
        frame = frame,
        modifier = "NONE",
        key = nil,
    }

    ---------------------------------------------------------
    -- Add label (required by AceConfigDialog)
    ---------------------------------------------------------
    local label = AceGUI:Create("Label")
    label:SetText("")
    label:SetFullWidth(true)

    ---------------------------------------------------------
    -- Create UI elements
    ---------------------------------------------------------
    local mod = AceGUI:Create("Dropdown")
    mod:SetList(modifierList, modifierOrder)
    mod:SetValue("NONE")
    mod:SetFullWidth(false)

    local button = AceGUI:Create("Button")
    button:SetText("Press Key")
    button:SetWidth(120)

    local result = AceGUI:Create("Label")
    result:SetText("|cffaaaaaaNo binding set|r")
    result:SetFullWidth(true)

    ---------------------------------------------------------
    -- Internal update logic
    ---------------------------------------------------------
    local function UpdateDisplay()
        if not widget.key then
            result:SetText("|cffaaaaaaNo binding set|r")
            widget.value = nil
            return
        end

        local txt = widget.key
        if widget.modifier ~= "NONE" then
            txt = widget.modifier .. "-" .. widget.key
        end

        widget.value = txt
        result:SetText("|cff00ff00" .. txt .. "|r")

        if widget.callback then
            widget.callback(widget.value)
        end
    end

    mod:SetCallback("OnValueChanged", function(_,_, val)
        widget.modifier = val
        UpdateDisplay()
    end)

    button:SetCallback("OnClick", function()
        MWM_KeyCapturePopup:StartCapture(function(k)
            if k then
                widget.key = k
                UpdateDisplay()
            end
        end)
    end)

    ---------------------------------------------------------
    -- Required methods for AceConfigDialog
    ---------------------------------------------------------
    function widget:OnAcquire()
        self.modifier = "NONE"
        mod:SetValue("NONE")
        self.key = nil
        UpdateDisplay()
    end

    function widget:OnRelease()
        -- cleanup if needed
    end

    function widget:SetLabel(text)
        label:SetText(text or "")
    end

    -- implement SetText() to satisfy AceConfigDialog
    function widget:SetText(text)
        label:SetText(text or "")
    end

    function widget:SetDisabled(disabled)
        mod:SetDisabled(disabled)
        button:SetDisabled(disabled)
    end

    function widget:SetValue(val)
        if not val or val == "" then return end

        local m, k = val:match("^([^%-]+)%-(.+)$")
        if not k then
            m = "NONE"
            k = val
        end

        self.modifier = m
        self.key = k

        mod:SetValue(m)
        UpdateDisplay()
    end

    function widget:GetValue()
        return self.value
    end

    function widget:SetCallback(cb)
        self.callback = cb
    end

    ---------------------------------------------------------
    -- Final Layout
    ---------------------------------------------------------
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)

    group:AddChild(label)
    group:AddChild(mod)
    group:AddChild(button)
    group:AddChild(result)

    widget.frame = group.frame
    widget.content = group.content

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
