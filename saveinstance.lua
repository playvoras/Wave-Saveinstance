local StandardOptioms = {
    noscripts = false, -- Decides if the File will include scripts or not.
    mode = "all", -- scripts if you only want to save scripts.
    maxTimeout = 10, -- Timeout for the Script
    fileName = "savedInstance.rbxlx", -- Default filename
    customDecompiler = false, -- If your Executor does not have a decompiler, use UniversalSynSaveInstance instead.
    disclude = "default" -- No use yet.
}

-- Helper function to escape XML special characters
local function escapeXml(value)
    return tostring(value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;")
end

-- Function to get the list of properties for an instance
local function getProperties(instance)
    local properties = {}
    for _, prop in ipairs({"Name", "ClassName", "Parent", "Archivable"}) do
        local success, value = pcall(function() return instance[prop] end)
        if success then
            properties[prop] = value
        end
    end
    return properties
end

-- Function to serialize properties of an instance
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

-- Function to serialize an instance to XML
local function serializeInstance(instance, options, statusLabel)
    local serialized = {}
    table.insert(serialized, string.format('<Item class="%s" referent="%s">', instance.ClassName, tostring(instance:GetDebugId())))
    table.insert(serialized, "<Properties>")
    table.insert(serialized, serializeProperties(instance))
    table.insert(serialized, "</Properties>")
    
    for _, child in ipairs(instance:GetChildren()) do
        -- Update status label for each child being decompiled
        statusLabel.Text = "Decompiling: " .. child:GetFullName()
        wait(0.05) -- Slight delay to allow UI update

        -- Include only scripts or all instances based on mode
        if options.mode == "all" or (options.mode == "scripts" and child:IsA("Script")) then
            if not options.noscripts or not child:IsA("Script") then
                table.insert(serialized, serializeInstance(child, options, statusLabel))
            end
        end
    end
    
    table.insert(serialized, "</Item>")
    return table.concat(serialized, "\n")
end

-- Function to create a TextLabel for status display
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

-- Main save instance function
function saveinstance(opt)
    local options = opt or StandardOptioms
    local instances = {}
    table.insert(instances, '<?xml version="1.0" encoding="utf-8"?>')
    table.insert(instances, '<roblox version="4">')
    
    -- Create a status label for feedback
    local statusLabel = createStatusLabel()

    -- Start serialization from the relevant services
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
    
    -- Update status label with the file size
    statusLabel.Text = "File size: " .. tostring(size) .. " bytes"

    -- Write the content to a file
    local fileName = options.fileName or "savedInstance.rbxlx"
    writefile(fileName, content)

    print("File saved as: " .. fileName .. " (Size: " .. size .. " bytes)")
end

-- Example usage
return saveinstance
