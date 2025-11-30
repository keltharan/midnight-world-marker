--========================================================--
--                    Logger.lua                          --
--       Complete Debug Window & Structured Inspector     --
--========================================================--

local AceGUI = LibStub("AceGUI-3.0")

local Logger = {}
_G.Logger = Logger

-----------------------------------------
-- Settings
-----------------------------------------
Logger.maxHistory = 1000

Logger.LEVEL_COLORS = {
    DEBUG = "|cffaaaaaa",
    INFO  = "|cff00ff00",
    WARN  = "|cffffcc00",
    ERROR = "|cffff0000",
}
Logger.COLOR_RESET = "|r"

Logger.levelEnabled = {
    DEBUG = true,
    INFO  = true,
    WARN  = true,
    ERROR = true,
}

Logger.entries = {}
Logger.window = nil
Logger.consoleScroll = nil
Logger.consoleBox = nil
Logger.searchText = ""
Logger.filterLevel = "All"

Logger.lastSelectedValue = nil
Logger.lastExpandedTree = {}

-----------------------------------------------------------
-- UTILITY
-----------------------------------------------------------

local function timestamp()
    return date("%H:%M:%S")
end

local function safe_tostring(v)
    local ok, r = pcall(function() return tostring(v) end)
    return ok and r or "<tostring error>"
end

local function is_array(tbl)
    local i = 0
    for k, _ in pairs(tbl) do
        if type(k) ~= "number" then return false end
        if k > i then i = k end
    end
    for n=1,i do
        if tbl[n] == nil then return false end
    end
    return true
end

local function serialize_value(v, indent, visited)
    indent = indent or 0
    visited = visited or {}

    local t = type(v)
    if t == "table" then
        if visited[v] then
            return "<recursive table>"
        end
        visited[v] = true

        local prefix = string.rep("  ", indent)
        local out = "{\n"

        if is_array(v) then
            for i=1,#v do
                out = out .. prefix .. "  [" .. i .. "] = " .. serialize_value(v[i], indent + 1, visited) .. "\n"
            end
        else
            for k,val in pairs(v) do
                out = out .. prefix .. "  " .. "[" .. safe_tostring(k) .. "] = " .. serialize_value(val, indent + 1, visited) .. "\n"
            end
        end

        return out .. prefix .. "}"
    elseif t == "function" then
        return "<function>"
    elseif t == "userdata" then
        return "<userdata>"
    else
        return safe_tostring(v)
    end
end

-----------------------------------------------------------
-- PUBLIC API
-----------------------------------------------------------

function Logger:Toggle()
    if self.window and self.window:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function Logger:Show()
    if not self.window then
        self:CreateWindow()
    end
    self.window:Show()
    self:UpdateConsole()
end

function Logger:Hide()
    if self.window then
        self.window:Hide()
    end
end

-----------------------------------------------------------
-- LOGGING API
-----------------------------------------------------------

function Logger:Log(level, ...)
    local msg = {}
    for i=1,select("#", ...) do
        local v = select(i, ...)
        if type(v) == "table" then
            table.insert(msg, serialize_value(v))
        else
            table.insert(msg, safe_tostring(v))
        end
    end
    local text = table.concat(msg, " ")

    table.insert(self.entries, {
        time = timestamp(),
        level = level,
        message = text,
        raw = {...},
    })

    if #self.entries > self.maxHistory then
        table.remove(self.entries, 1)
    end

    self:UpdateConsole()
end

function Logger:Debug(...) self:Log("DEBUG", ...) end
function Logger:Info(...)  self:Log("INFO", ...) end
function Logger:Warn(...)  self:Log("WARN", ...) end
function Logger:Error(...) self:Log("ERROR", ...) end

-----------------------------------------------------------
-- UI CREATION
-----------------------------------------------------------

function Logger:CreateWindow()
    local frame = AceGUI:Create("Frame")
    self.window = frame
    frame:SetTitle("Logger & Inspector")
    frame:SetLayout("Fill")
    frame:SetWidth(900)
    frame:SetHeight(550)
    frame:EnableResize(true)

    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("Flow")
    tabs:SetTabs({
        {text="Console", value="console"},
        {text="Inspector", value="inspector"},
    })
    tabs:SetCallback("OnGroupSelected", function(_, _, g)
        self:SelectTab(g)
    end)
    frame:AddChild(tabs)

    tabs:SelectTab("console")
end

function Logger:SelectTab(tab)
    if tab == "console" then
        self:CreateConsole()
    else
        self:CreateInspector()
    end
end

-----------------------------------------------------------
-- CONSOLE VIEW
-----------------------------------------------------------
function Logger:CreateConsole()
    local container = self.window.children[1]
    container:ReleaseChildren()

    -----------------------------------------
    -- Legend
    -----------------------------------------
    local legend = AceGUI:Create("SimpleGroup")
    legend:SetLayout("Flow")
    legend:SetFullWidth(true)
    local function makeLegend(level)
        local l = AceGUI:Create("Label")
        l:SetWidth(80)
        l:SetText(self.LEVEL_COLORS[level] .. level .. self.COLOR_RESET)
        legend:AddChild(l)
    end
    makeLegend("DEBUG")
    makeLegend("INFO")
    makeLegend("WARN")
    makeLegend("ERROR")
    container:AddChild(legend)

    -----------------------------------------
    -- Per-Level ON/OFF toggles
    -----------------------------------------
    local toggles = AceGUI:Create("SimpleGroup")
    toggles:SetFullWidth(true)
    toggles:SetLayout("Flow")

    local function addToggle(level)
        local btn = AceGUI:Create("Button")
        btn:SetWidth(100)

        local function refresh()
            btn:SetText(
                self.LEVEL_COLORS[level]
                .. level .. ": "
                .. (self.levelEnabled[level] and "ON" or "OFF")
                .. self.COLOR_RESET
            )
        end

        refresh()

        btn:SetCallback("OnClick", function()
            self.levelEnabled[level] = not self.levelEnabled[level]
            refresh()
            self:UpdateConsole()
        end)

        toggles:AddChild(btn)
    end

    addToggle("DEBUG")
    addToggle("INFO")
    addToggle("WARN")
    addToggle("ERROR")

    container:AddChild(toggles)

    -----------------------------------------
    -- SEARCH + COPY ROW
    -----------------------------------------
    local searchGroup = AceGUI:Create("SimpleGroup")
    searchGroup:SetFullWidth(true)
    searchGroup:SetLayout("Flow")

    local search = AceGUI:Create("EditBox")
    search:SetLabel("Search")
    search:SetWidth(300)
    search:SetCallback("OnTextChanged", function(_,_,text)
        self.searchText = text
        self:UpdateConsole()
    end)
    searchGroup:AddChild(search)

    local copyBtn = AceGUI:Create("Button")
    copyBtn:SetText("Copy All")
    copyBtn:SetWidth(120)
    copyBtn:SetCallback("OnClick", function()
        local full = {}
        for _,e in ipairs(self.entries) do
            table.insert(full, string.format("[%s] [%s] %s", e.time, e.level, e.message))
        end
        self:OpenCopyWindow(table.concat(full, "\n"))
    end)
    searchGroup:AddChild(copyBtn)

    container:AddChild(searchGroup)

    -----------------------------------------
    -- Scrollable text area
    -----------------------------------------
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")

    self.consoleScroll = scroll
    -- call this once when creating the scroll frame
    self.consoleScroll.scrollframe:SetScript("OnUpdate", function(sf)
      if self.consoleScroll.scrollToBottom then
          local max = sf:GetVerticalScrollRange()
          sf:SetVerticalScroll(max)
          self.consoleScroll.scrollToBottom = nil
      end
    end)
        container:AddChild(scroll)

    self:UpdateConsole()
end


function Logger:UpdateConsole()
    if not self.consoleScroll then return end
    self.consoleScroll:ReleaseChildren()

    for _, entry in ipairs(self.entries) do
        if self.levelEnabled[entry.level] then
            if self.searchText == "" or entry.message:lower():find(self.searchText:lower(), 1, true) then
                local line = AceGUI:Create("Label")
                line:SetFullWidth(true)
                line:SetText(
                    string.format("%s[%s][%s]%s: %s",
                        self.LEVEL_COLORS[entry.level],
                        entry.time,
                        entry.level,
                        self.COLOR_RESET,
                        entry.message
                    )
                )

                line.entry = entry
                line:SetCallback("OnClick", function()
                    self:SelectInspectorValue(entry.raw)
                end)

                self.consoleScroll:AddChild(line)
            end
        end
    end
    self:ScrollToBottom()
end

-----------------------------------------------------------
-- FORCE SCROLL TO BOTTOM
-----------------------------------------------------------
function Logger:ScrollToBottom()
  if not self.consoleScroll or not self.consoleScroll.scrollframe or not self.consoleScroll.scrollchild then return end

  -- set a flag that we want to scroll after layout
  self.consoleScroll.scrollToBottom = true
end

-----------------------------------------------------------
-- INSPECTOR VIEW
-----------------------------------------------------------
function Logger:CreateInspector()
    local container = self.window.children[1]
    container:ReleaseChildren()

    self.inspectorTree = AceGUI:Create("TreeGroup")
    self.inspectorTree:SetLayout("Fill")
    self.inspectorTree:SetFullWidth(true)
    self.inspectorTree:SetFullHeight(true)
    self.inspectorTree:SetCallback("OnClick", function(_,_,node)
        -- nothing
    end)
    self.inspectorTree:SetCallback("OnGroupSelected", function(_,_,node)
        self:OnInspectorSelect(node)
    end)

    container:AddChild(self.inspectorTree)

    if self.lastSelectedValue then
        self:PopulateInspector(self.lastSelectedValue)
    else
        self.inspectorTree:SetTree({{text="No selection", value="none"}})
    end
end

function Logger:SelectInspectorValue(val)
    self.lastSelectedValue = val
    self:SelectTab("inspector")
end

function Logger:PopulateInspector(value)
    local function build(v, key)
        local t = type(v)
        local node = {
            text = (key and (safe_tostring(key) .. ": ") or "") .. "(" .. t .. ")",
            value = tostring(v),
            children = {}
        }

        if t == "table" then
            for k,val in pairs(v) do
                table.insert(node.children, build(val, k))
            end
        else
            table.insert(node.children, {
                text = safe_tostring(v)
            })
        end
        return node
    end

    local tree = { build(value, "root") }
    self.inspectorTree:SetTree(tree)
end

function Logger:OnInspectorSelect(node)
    -- optional: show node value
end

-----------------------------------------------------------
-- COPY WINDOW
-----------------------------------------------------------
function Logger:OpenCopyWindow(text)
    local win = AceGUI:Create("Frame")
    win:SetTitle("Copy Output")
    win:SetLayout("Fill")
    win:SetWidth(600)
    win:SetHeight(400)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetFullWidth(true)
    box:SetFullHeight(true)
    box:SetText(text)
    win:AddChild(box)
end

-----------------------------------------------------------
-- RETURN
-----------------------------------------------------------
return Logger
