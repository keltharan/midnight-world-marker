-- Options.lua - uses bundled Ace stubs if present, else fallback
local ADDON, ns = ...
local MwMarkers = ns.Addon

if not MwMarkers.Options then
    MwMarkers.Options = {}
end

_G['MW_Options'] = MwMarkers.Options

MwMarkers.Options.MARKERS = {'none','square','triangle','diamond','cross','star','circle','moon','skull'}
MwMarkers.Options.MARKERS_ORDER = {none = 0, square = 1, triangle = 2, diamond = 3, cross = 4, star = 5, circle = 6, moon = 7, skull = 8}

function MwMarkers.Options:OpenConfig()
  LibStub("AceConfigDialog-3.0"):Open("Midnight World Markers")
  MwMarkers.Options:DisableResize()
end

function MwMarkers.Options:DisableResize()
  -- Get the actual AceGUI frame
  local frame = LibStub("AceConfigDialog-3.0").OpenFrames["Midnight World Markers"]
  if not frame then return end

  frame.sizer_se:Hide()
  frame.sizer_s:Hide()
  frame.sizer_e:Hide()
end

function MwMarkers.Options:SaveOptions()
  if MwMarkers.Core then
    MwMarkers.Core:Refresh()
  end
end

function MwMarkers.Options:Init()
  self.MW = MwMarkers
  self.db = MwMarkers.db

  local ok, AceConfig = pcall(function() return LibStub:GetLibrary('AceConfig-3.0', true) end)
  local ok2, AceConfigDialog = pcall(function() return LibStub:GetLibrary('AceConfigDialog-3.0', true) end)

  if not ok or not ok2 or not AceConfig or not AceConfigDialog then
    return
  end

  local menu = {
    name = MwMarkers.Const.Text.ADDON_R_NAME,
    handler = MwMarkers,
    type = 'group',
    childGroups =  "tabs",
    args = {
    }
  }

  MwMarkers.Options.Config:Init(AceConfigDialog, menu)
  MwMarkers.Profile:Init(menu)
  
  AceConfig:RegisterOptionsTable(MwMarkers.Const.Text.ADDON_R_NAME, menu)
  AceConfigDialog:AddToBlizOptions(MwMarkers.Const.Text.ADDON_R_NAME,MwMarkers.Const.Text.ADDON_R_NAME)
end

return MwMarkers.Options
