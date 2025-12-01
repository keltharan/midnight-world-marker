-- MidnightWorldMarkers.lua - Core initializer and public API (vendored libs included)
local ADDON_NAME, ns = ...

local MwMarkers = LibStub("AceAddon-3.0"):NewAddon(
    ADDON_NAME,
    "AceConsole-3.0",
    "AceEvent-3.0"
)

ns.Addon = MwMarkers

local LibDualSpec = LibStub("LibDualSpec-1.0", true)

function MwMarkers:OnInitialize()
  -- Load defaults (from Core/Constants.lua)
  local defaults = MwMarkers.Const.Defaults
  if not defaults then
      error(ADDON_NAME..": Defaults not loaded! Make sure Core/Constants.lua is loaded before "..ADDON_NAME..".lua")
  end

  self.db = LibStub("AceDB-3.0"):New(ADDON_NAME.."_DB", defaults, true)
  ns.db = self.db

  self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileCopied",  "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileReset",   "OnProfileChanged")

  -- Enhance database with LibDualSpec if available
  if LibDualSpec then
      LibDualSpec:EnhanceDatabase(self.db, ADDON_NAME.."_DB")
  end
  
  -- Register chat commands
  self:RegisterChatCommand("mwm", "OpenConfig")
  self:RegisterChatCommand("mwmarkers", "OpenConfig")
  self:RegisterChatCommand("mwm-logger", "OpenLogger")

  self:OnLoaded(defaults)
end


function MwMarkers:OpenLogger()
  if _G.Logger then
    _G.Logger:Toggle()
  end
end

function MwMarkers:OpenConfig()
  if MwMarkers.Options and MwMarkers.Options.OpenConfig then MwMarkers.Options:OpenConfig()
  else InterfaceOptionsFrame_OpenToCategory(ADDON_NAME) end
end

function MwMarkers:OnProfileChanged(event, db, profileKey)
    if self.RefreshAll then
        self:RefreshAll()
    end
end

function MwMarkers:OnLoaded(defaults)
  MwMarkers.db.profile = MwMarkers.db.profile or defaults.profile

  MwMarkers.db.profile.dropdowns = MwMarkers.db.profile.dropdowns or {unpack(defaults.profile.dropdowns)}
  MwMarkers.Utils.ensure_unique(MwMarkers.db.profile.dropdowns)
  MwMarkers.db.profile.markers = MwMarkers.Utils.make_markers_array(MwMarkers.db.profile.dropdowns)
  MwMarkers.db.profile.minimap = MwMarkers.db.profile.minimap or { hide = false, pos = 45 }

  MwMarkers.Options:Init()
  MwMarkers.Core:Init()
  MwMarkers.Minimap:Init()
end

function MwMarkers:RefreshAll()
  MwMarkers.Core:Refresh()
end