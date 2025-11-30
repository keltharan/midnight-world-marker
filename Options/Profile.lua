local ADDON_NAME, ns = ...
local MwMarkers = ns.Addon

if not MwMarkers.Profile then
    MwMarkers.Profile = {}
end

_G['MW_Profile'] = MwMarkers.Profile

local importBuffer = ""

local AceSerializer = LibStub("AceSerializer-3.0", true)
local LibDeflate    = LibStub("LibDeflate", true)
local AceDBOptions = LibStub("AceDBOptions-3.0", true)
local LibDualSpec   = LibStub("LibDualSpec-1.0", true)

function MwMarkers.Profile:Init(menu)
  
    self.db = MwMarkers.db
    local options = {
      name = 'Profile',
      type = 'group',
      inline = false,
      width = "full",
      args = {
        import = MwMarkers.Profile:CreateProfileOptions()
      }
    }

    menu.args.profile = options;

    local profileOptions
    if AceDBOptions and self.db then
        profileOptions = AceDBOptions:GetOptionsTable(self.db)
        -- Enhance profile options with LibDualSpec if available
        if LibDualSpec then
            LibDualSpec:EnhanceOptions(profileOptions, self.db)
        end
    end
    
    if profileOptions then
        -- Copy all properties from profileOptions first
        options.args.profiles = {}
        for k, v in pairs(profileOptions) do
            options.args.profiles[k] = v
        end
        -- Override name and order
        options.args.profiles.name = "Profiles"
        options.args.profiles.order = 98
    end
end

function MwMarkers.Profile:CreateProfileOptions()
    return {
        type = "group",
        name = "Import / Export",
        order = 99,
        args = {
            desc = {
                type  = "description",
                order = 1,
                name  = "Export your current profile as text to share, or paste a string to import.",
            },

            spacer1 = {
                type  = "description",
                order = 2,
                name  = "",
            },

            export = {
                type      = "input",
                name      = "Export Current Profile",
                order     = 10,
                width     = "full",
                multiline = true,
                get       = function()
                    return MwMarkers.Profile:ExportProfileToString()
                end,
                set       = function() end,
            },

            spacer2 = {
                type  = "description",
                order = 19,
                name  = " ",
            },

            import = {
                type      = "input",
                name      = "Import Profile String",
                order     = 20,
                width     = "full",
                multiline = true,
                get       = function()
                    return importBuffer
                end,
                set       = function(_, val)
                    importBuffer = val or ""
                end,
            },

            importButton = {
                type  = "execute",
                name  = "Import",
                order = 30,
                func  = function()
                    local importString = importBuffer
                    
                    -- If buffer is empty, try to get text directly from the widget
                    if not importString or importString == "" then
                        local AceConfigDialog = LibStub("AceConfigDialog-3.0")
                        local openFrame = AceConfigDialog.OpenFrames[ADDON_NAME]
                        if openFrame then
                            local function FindImportWidget(parent, depth)
                                depth = depth or 0
                                if depth > 15 then return nil end
                                
                                -- Check if this is a multiline EditBox widget
                                if type(parent) == "table" and parent.type == "MultiLineEditBox" and parent.editBox then
                                    local label = parent.label and parent.label:GetText() or ""
                                    if string.find(label:lower(), "import") then
                                        return parent.editBox:GetText() or ""
                                    end
                                end
                                
                                -- Check children
                                if type(parent) == "table" and parent.children then
                                    for _, widget in pairs(parent.children) do
                                        local text = FindImportWidget(widget, depth + 1)
                                        if text then return text end
                                    end
                                end
                                
                                -- Check frame
                                if type(parent) == "table" and parent.frame then
                                    local text = FindImportWidget(parent.frame, depth + 1)
                                    if text then return text end
                                end
                                
                                -- Check WoW frames
                                if type(parent) == "userdata" and parent.GetChildren then
                                    local children = {parent:GetChildren()}
                                    for _, child in ipairs(children) do
                                        local text = FindImportWidget(child, depth + 1)
                                        if text then return text end
                                    end
                                end
                                
                                return nil
                            end
                            
                            importString = FindImportWidget(openFrame, 0) or importBuffer
                        end
                    end
                    
                    -- Trim whitespace
                    if importString then
                        importString = importString:gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    
                    if not importString or importString == "" then
                        print("|cffff0000MwMarkers: Import failed: No data found. Please paste your import string in the Import Profile String field.|r")
                        return
                    end
                    
                    local ok, err = MwMarkers.Profile:ImportProfileFromString(importString)
                    if ok then
                        print("|cff00ff00MwMarkers: Profile imported. Config refreshed!|r")
                        -- Clear the import buffer after successful import
                        importBuffer = ""
                        if MwMarkers.RefreshAll then
                            MwMarkers:RefreshAll()
                        end
                    else
                        print("|cffff0000MwMarkers: Import failed: " .. (err or "Unknown error") .. "|r")
                    end
                end,
            },
            spacer3 = {
                type  = "description",
                order = 31,
                name  = "|cff00ff00PRESSING THE IMPORT BUTTON WILL OVERWRITE YOUR CURRENT PROFILE|r",
            },
        },
    }
end


function MwMarkers.Profile:ImportProfileFromString(str)
    if not self.db or not self.db.profile then
        return false, "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return false, "Import requires AceSerializer-3.0 and LibDeflate."
    end
    if not str or str == "" then
        return false, "No data provided."
    end

    str = str:gsub("%s+", "")
    str = str:gsub("^MWM1:", "")

    local compressed = LibDeflate:DecodeForPrint(str)
    if not compressed then
        return false, "Could not decode string (maybe corrupted)."
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return false, "Could not decompress data."
    end

    local ok, t = AceSerializer:Deserialize(serialized)
    if not ok or type(t) ~= "table" then
        return false, "Could not deserialize profile."
    end

    local profile = self.db.profile
    for k in pairs(profile) do
        profile[k] = nil
    end
    for k, v in pairs(t) do
        profile[k] = v
    end

    if MwMarkers.RefreshAll then
        MwMarkers:RefreshAll()
    end

    return true
end
-- Profile Import/Export
function MwMarkers.Profile:ExportProfileToString()
    if not self.db or not self.db.profile then
        return "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return "Export requires AceSerializer-3.0 and LibDeflate."
    end

    local serialized = AceSerializer:Serialize(self.db.profile)
    if not serialized or type(serialized) ~= "string" then
        return "Failed to serialize profile."
    end

    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
        return "Failed to compress profile."
    end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return "Failed to encode profile."
    end

    return "MWM1:" .. encoded
end


return MwMarkers.Profile
