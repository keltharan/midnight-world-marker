-- Minimap.lua - uses vendored LibDBIcon if present, else fallback draggable button
local ADDON_NAME, ns = ...
local MwMarkers = ns.Addon

if not MwMarkers.Minimap then
    MwMarkers.Minimap = {}
end


function  MwMarkers.Minimap:Init()
  local LDB = LibStub("LibDataBroker-1.1", true)
  local LibDBIcon = LibStub("LibDBIcon-1.0", true)
  
  if not LDB or not LibDBIcon then
      return
  end
  
  -- Initialize minimap button database
  if not MwMarkers.db.profile.minimap then
    MwMarkers.db.profile.minimap = {
      hide = false,
    }
  end
  
  -- Create DataBroker object
  local dataObj = LDB:NewDataObject(ADDON_NAME, {
      type = "launcher",
      icon = "Interface\\AddOns\\MidnightWorldMarkers\\Media\\icon.tga",
      label = MwMarkers.Const.Text.ADDON_R_NAME,
      OnClick = function(_, button)
          if button == "LeftButton" or button == "RightButton" then
              -- Right click could toggle something or show a menu
              -- For now, just open config
              if MwMarkers.Options and MwMarkers.Options.OpenConfig then MwMarkers.Options:OpenConfig()
              else InterfaceOptionsFrame_OpenToCategory(ADDON_NAME) end
          end
      end,
      OnTooltipShow = function(tooltip)
          tooltip:SetText(MwMarkers.Const.Text.ADDON_R_NAME)
          tooltip:AddLine("Left-click to open configuration", 1, 1, 1)
          tooltip:AddLine("Right-click to open configuration", 1, 1, 1)
      end,
  })
  
  -- Register with LibDBIcon
  LibDBIcon:Register(ADDON_NAME, dataObj, MwMarkers.db.profile.minimap)
end

return MwMarkers.Minimap
