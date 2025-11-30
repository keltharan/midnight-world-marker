local ADDON, ns = ...
local MwMarkers = ns.Addon

if not MwMarkers.Utils then
    MwMarkers.Utils = {}
end

function MwMarkers.Utils.make_markers_array(dd)
    local out = {}
    for _,v in ipairs(dd) do if v ~= 'none' then table.insert(out, v) end end
    return out
end
    
function MwMarkers.Utils.ensure_unique(dd)
    local seen = {}
    for i,v in ipairs(dd) do
    if v ~= 'none' then
        if seen[v] then dd[i] = 'none' else seen[v] = true end
    end
    end
end

return MwMarkers.Utils