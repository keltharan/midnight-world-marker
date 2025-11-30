
local ADDON, ns = ...
local MwMarkers = ns.Addon

MwMarkers.Const = {
    Text = {
        ADDON_R_NAME = "Midnight World Markers"
    },
    Defaults = {
        profile = {
            dropdowns = {'none','none','none','none','none','none','none','none'},
            markers = {},
            minimap = { hide = false, pos = 45 },
            
        }
    }
}

_G['MW_Core_Const'] = MwMarkers.Const
return MwMarkers.Const