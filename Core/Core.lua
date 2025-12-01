-- Options.lua - uses bundled Ace stubs if present, else fallback
local ADDON, ns = ...
local MwMarkers = ns.Addon

if not MwMarkers.Core then
    MwMarkers.Core = {}
end

_G['MW_Core'] = MwMarkers.Core

function MwMarkers.Core:Refresh()
    local button = _G["MW_Core_MarkerCycler"]
    if not button then
        button = CreateFrame("Button", "MW_Core_MarkerCycler", nil, "SecureActionButtonTemplate")
        button:SetAttribute("type", "macro")
        button:RegisterForClicks("AnyUp", "AnyDown")
    end


    local body = "i = 0;order = newtable()"
    local clearMarks = ""
    local arr = (self.db and self.db.profile and self.db.profile.markers) or {}
    local clearAll = self.db.profile.reset and self.db.profile.reset.clearAll;

    for i = 1, 8 do
        local val = self.MwMarkers.Options.MARKERS_ORDER[arr[i]]
        if val and val ~= 0 then
            body = body .. string.format("tinsert(order, %s)", val)

            if not clearAll then
                clearMarks = clearMarks .. string.format("\n/cwm %s", val)
            end
        end
        if clearAll then
            clearMarks = clearMarks .. string.format("\n/cwm %s", i)
        end
    end
    
    body = body .. ";clearMarks=[["..clearMarks.."]];";

    SecureHandlerExecute(button, body)
    SecureHandlerUnwrapScript(button, "PreClick")
    SecureHandlerWrapScript(button, "PreClick", button, [=[
            if not down or not next(order) then
                return
            end

            if button == "reset" then
                i = 0
                self:SetAttribute("macrotext", clearMarks)
            else
                i = i%#order + 1
                self:SetAttribute("macrotext", "/wm [@cursor]"..order[i])
            end
    ]=])

    local frame = _G["MW_Core_MarkerCyclerBinding"] or CreateFrame("Frame", "MW_Core_MarkerCyclerBinding")
    ClearOverrideBindings(frame)
    for _, action in ipairs({"place", "reset"}) do
         if self.db.profile[action] and self.db.profile[action].key ~= "" and self.db.profile[action].key then
            SetOverrideBindingClick(frame, true, (((self.db.profile[action].modifier or "NONE") ~= "NONE" and (self.db.profile[action].modifier .. "-") or "") .. (self.db.profile[action].key or "")), button:GetName(), action)
        end
    end
end


function MwMarkers.Core:Init()
    self.MwMarkers = MwMarkers
    self.db = MwMarkers.db

    MwMarkers.Core:Refresh()
  end
  
  return MwMarkers.Core