local StandardOptioms = {
    noscripts = false,
    mode = "all",
    maxTimeout = 10,
    fileName = "savedInstance.rbxlx",
    customDecompiler = false,
    disclude = "default"
}

local function escapeXml(value)
    return tostring(value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;")
end

local function getProperties(instance)
    local properties = {}
    for _, prop in ipairs({"Name", "ClassName", "Parent", "Archivable"}) do
        local success, value = pcall(function() return instance[prop] end)
        if success then properties[prop] = value end
    end
    return properties
end

local function serializeProperties(instance)
    local properties = {}
    local props = getProperties(instance)
    for prop, value in pairs(props) do
        if typeof(value) == "Instance" then
            value = value:GetFullName()
        end
        value = escapeXml(tostring(value))
        table.insert(properties, string.format("<%s>%s</%s>", prop, value, prop))
    end
    return table.concat(properties, "\n")
end

local function serializeInstance(instance, options, statusLabel)
    local serialized = {}
    table.insert(serialized, string.format('<Item class="%s" referent="%s">', instance.ClassName, tostring(instance:GetDebugId())))
    table.insert(serialized, "<Properties>")
    table.insert(serialized, serializeProperties(instance))
    table.insert(serialized, "</Properties>")
    
    for _, child in ipairs(instance:GetChildren()) do
        statusLabel.Text = "Decompiling: " .. child:GetFullName()
        wait(0.05)
        if options.mode == "all" or (options.mode == "scripts" and child:IsA("Script")) then
            if not options.noscripts or not child:IsA("Script") then
                table.insert(serialized, serializeInstance(child, options, statusLabel))
            end
        end
    end
    
    table.insert(serialized, "</Item>")
    return table.concat(serialized, "\n")
end

local function createStatusLabel()
    local screenGui = Instance.new("ScreenGui", game.CoreGui)
    local textLabel = Instance.new("TextLabel", screenGui)
    textLabel.Size = UDim2.new(0, 400, 0, 50)
    textLabel.Position = UDim2.new(0.5, -200, 0, 0)
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 0.5
    textLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    textLabel.TextScaled = true
    textLabel.Text = "Initializing..."
    return textLabel
end

function saveinstance(opt)
    local options = opt or StandardOptioms
    local instances = {}
    table.insert(instances, '<?xml version="1.0" encoding="utf-8"?>')
    table.insert(instances, '<roblox version="4">')
    
    local statusLabel = createStatusLabel()

    local topLevelServices = {
        game.ReplicatedStorage,
        game.ReplicatedFirst,
        game.StarterPlayer,
        game.Workspace,
        game.StarterGui,
        game.StarterPack,
        game.Teams,
        game.Lighting
    }
    
    for _, service in ipairs(topLevelServices) do
        statusLabel.Text = "Decompiling: " .. service:GetFullName()
        table.insert(instances, serializeInstance(service, options, statusLabel))
    end
    
    table.insert(instances, '</roblox>')

    local content = table.concat(instances, "\n")
    local size = #content
    statusLabel.Text = "File size: " .. tostring(size) .. " bytes"
    local fileName = options.fileName or "savedInstance.rbxlx"
    writefile(fileName, content)

    print("File saved as: " .. fileName .. " (Size: " .. size .. " bytes)")
end

saveinstance()
