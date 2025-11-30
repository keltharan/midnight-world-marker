local ADDON, ns = ...
local MwMarkers = ns.Addon
if not MwMarkers.Options then
    MwMarkers.Options = {}
end

MwMarkers.Options.Config = {}
_G['MwMarkers.Options.Config'] = MwMarkers.Options.Config;

local markerCoords = {
    star     = {0,     0.25, 0,     0.25},
    circle   = {0.25,  0.5,  0,     0.25},
    diamond  = {0.5,   0.75, 0,     0.25},
    triangle = {0.75,  1,    0,     0.25},
    moon     = {0,     0.25, 0.25,  0.5},
    square   = {0.25,  0.5,  0.25,  0.5},
    cross    = {0.5,   0.75, 0.25,  0.5},
    skull    = {0.75,  1,    0.25,  0.5},
  }

  local function Icon(marker, label)
    local c = markerCoords[marker]
    return string.format(
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:16:16:0:0:256:256:%s:%s:%s:%s|t %s",
        c[1]*256, c[2]*256, c[3]*256, c[4]*256,
        label
    )
  end

  local markerList = {
    none     = "|cff888888None|r",
    star     = Icon("star", ""),
    circle   = Icon("circle", ""),
    square   = Icon("square", ""),
    diamond  = Icon("diamond", ""),
    moon     = Icon("moon", ""),
    triangle = Icon("triangle", ""),
    cross    = Icon("cross", ""),
    skull    = Icon("skull", ""),
  }

  local modifiers = {
    ['NONE'] ="None",
    ['SHIFT'] ="Shift",
    ['CTRL'] ="Ctrl",
    ['ALT'] ="Alt",
    ['CTRL-SHIFT'] ="Shift+Ctrl",
    ['ALT-SHIFT'] ="Shift+Alt",
    ['ALT-CTRL'] ="Ctrl+Alt",
    ['ALT-CTRL-SHIFT'] ="Shift+Ctrl+Alt",
  }

  local mouseMap = {
      ["BUTTON1"] = "Left Click",
      ["BUTTON2"] = "Right Click",
      ["BUTTON3"] = "Middle Click",
      ["BUTTON4"] = "Button4",
      ["BUTTON5"] = "Button5",
  }

  local function make_markers_array(dd)
    local out={}
    for _,v in ipairs(dd) do if v ~= 'none' then table.insert(out,v) end end
    return out
  end

  local function ensure_unique(dd)
    local seen={}
    for i,v in ipairs(dd) do
      if v ~= 'none' then
        if seen[v] then dd[i] = 'none' else seen[v]=true end
      end
    end
  end

function MwMarkers.Options.Config:Init(AceConfigDialog, menu)
    self.MwMarkers = MwMarkers
    self.db = MwMarkers.db

    MwMarkers.Options.Config:InitOptions(AceConfigDialog, menu)
  end

function MwMarkers.Options.Config:InitOptions(AceConfigDialog, menu)
    local dropdowns = {
      name = 'Markers',
      type = 'group',
      inline = true,
      width = "full",
      order = 1,
      args = {
        desc = { type = 'description', order = 1, name = 'Select up to 8 unique markers.' },
      }
    }

    local options = {
      name = 'Configuration',
      type = 'group',
      inline = false,
      width = "full",
      args = {
        dropdowns = dropdowns
      }
    }

    menu.args.options = options;
    MwMarkers.Options.Config:InitMarksSection(dropdowns)
    MwMarkers.Options.Config:InitKeyAssignmentSection(AceConfigDialog, options, "place")
    MwMarkers.Options.Config:InitKeyAssignmentSection(AceConfigDialog, options, "reset")
  end


  function MwMarkers.Options.Config:InitMarksSection(options)
    for i=1,8 do
      options.args['marker'..i] = {
        type = 'select',
        name = ' Marker '..i,
        order = 10+i,
        values = markerList,
        sorting = self.MwMarkers.Options.MARKERS,
        style = "dropdown",
        width = 0.42,
        get = function()
          return self.db.profile.dropdowns[i]
        end,
        set = function(_, val)
          self.db.profile.dropdowns[i] = val
          ensure_unique(self.db.profile.dropdowns)
          self.db.profile.markers = make_markers_array(self.db.profile.dropdowns)
          self.MwMarkers.Options:SaveOptions()
        end
      }
    end
  end

  function MwMarkers.Options.Config:InitKeyAssignmentSection(AceConfigDialog, options, action)
    local group = "Marks "..action:gsub("^%l", string.upper).." Hotkey";
    options.args[action] = {
      type = "group",
      name = group,
      order= 10,
      inline = true,
      width = "full",
      args = {
          modifier = {
              type = "select",
              name = " ",
              desc = "Select the modifier that should be used together with the specified key.",
              values = modifiers,
              width = 0.7,
              order = 1,
              get = function() return self.db.profile[action].modifier or "NONE" end,
              set = function(_, val)
                  if not self.db.profile[action] then
                    self.db.profile[action] = {modifier = "NONE", key = nil}
                  end
                  self.db.profile[action].modifier = val
                  self.MwMarkers.Options:SaveOptions()
              end,
          },

          assign = {
              type = "execute",
              name = "Assign Key",
              width = 0.9,
              order = 2,
              func = function()
                  MWM_KeyCapturePopup:StartCapture(function(key)
                      if key then
                        if not self.db.profile[action] then
                            self.db.profile[action] = {modifier = "NONE", key = nil}
                          end
                          self.db.profile[action].key = key
                          self.MwMarkers.Options:SaveOptions()
                          AceConfigDialog:SelectGroup('Midnight World Markers', group)
                      end
                  end)
              end,
          },
          current = {
              type = "description",
              order = 0.8,
              name = function()
                if not self.db.profile[action] then
                  self.db.profile[action] = {modifier = "NONE", key = nil}
                end
                if not self.db.profile[action].key then return "\nCurrent Binding: |cffff5555None|r" end
                return "\nCurrent Binding: |cff55ff55" .. ((self.db.profile[action].modifier ~= "NONE" and (self.db.profile[action].modifier .. "-") or "") .. (mouseMap[self.db.profile[action].key] or self.db.profile[action].key or "")) .. "|r"
              end,
              fontSize = "medium",
          },
      },
    }

    if action == "reset" then
      options.args[action].args.clearAll = {
        type = "toggle",
        name = "Clear All",
        desc = "If checked the reset key will clear all marks not just the selected.",
        width = "quarter",
        order = 3,
        get = function(_)
            return self.db.profile[action].clearAll
        end,
        set = function(_, val)
            self.db.profile[action].clearAll = val
            self.MwMarkers.Options:SaveOptions()
        end,
      }
    end
  end

  return MwMarkers.Options.Config