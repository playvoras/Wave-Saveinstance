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

-- Function to serialize properties of an instance
local function serializeProperties(instance)
    local properties = {}

    for _, prop in ipairs(instance:GetProperties()) do
        local success, value = pcall(function() return instance[prop] end)
        if success then
            if typeof(value) == "Instance" then
                value = value:GetFullName()
            end
            value = escapeXml(tostring(value))
            table.insert(properties, string.format("<%s>%s</%s>", prop, value, prop))
        end
    end

    return table.concat(properties, "\n")
end

-- Function to serialize an instance to XML
local function serializeInstance(instance, options)
    local serialized = {}
    table.insert(serialized, string.format('<Item class="%s" referent="%s">', instance.ClassName, tostring(instance:GetDebugId())))
    table.insert(serialized, "<Properties>")
    table.insert(serialized, serializeProperties(instance))
    table.insert(serialized, "</Properties>")
    
    for _, child in ipairs(instance:GetChildren()) do
        if options.mode == "all" or (options.mode == "scripts" and child:IsA("Script")) then
            if not options.noscripts or not child:IsA("Script") then
                table.insert(serialized, serializeInstance(child, options))
            end
        end
    end
    
    table.insert(serialized, "</Item>")
    return table.concat(serialized, "\n")
end

-- Main save instance function
function saveinstance(opt)
    local options = opt or StandardOptioms
    local instances = {}
    table.insert(instances, '<?xml version="1.0" encoding="utf-8"?>')
    table.insert(instances, '<roblox version="4">')

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
        table.insert(instances, serializeInstance(service, options))
    end
    
    table.insert(instances, '</roblox>')

    local content = table.concat(instances, "\n")
    local size = #content

    -- Write the content to a file
    local fileName = options.fileName or "savedInstance " .. game.PlaceId .. ".rbxlx"
    writefile(fileName, content)

    print("File saved as: " .. fileName .. " (Size: " .. size .. " bytes)")
end

-- Example usage
--saveinstance(StandardOptioms)
