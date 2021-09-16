local macbeth = {
	name = "Macbeth",
	version="0.1",
	author="Mikolaj Holysz <miki123211@gmail.com>",
	license = "The Unlicense, <https://unlicense.org>",
	homepage="https://github.com/mikolysz/macbeth",
	
	automationHandlers = {
		lua = function(path)
			return function()
				dofile(path)
			end
		end,
	},
}


local logger = hs.logger.new("Macbeth")
logger.setLogLevel("info")

local userAutomationsPath = "~/Documents/My Macbeth Automations"

local registeredAutomations = {}

local function audioHandler(path)
	local sound = hs.sound.getByFile(path)
	return function()
		sound:play()
	end
end

-- add audio handlers
for _, type in pairs(hs.sound.soundFileTypes()) do
	macbeth.automationHandlers[type] = audioHandler
end


function macbeth:start()
	-- Create the user automations directory (if it doesn't exist)
	local exists = hs.fs.attributes(userAutomationsPath)
	if not exists then
		logger.i("Directory '" .. userAutomationsPath .. "' doesn't exist, creating...")
		hs.fs.mkdir(userAutomationsPath)
	end

	macbeth:registerAutomations()	
	Macbeth:setupHotkeys()
	logger.i("Macbeth is ready")
	macbeth:handleEvent("macbeth.started")
end

function macbeth:handleEvent(name)
	local automations = registeredAutomations[name]
	if not automations then
		logger.i("No automations for event " .. name)
		return
	end
	
	for i = 1, #automations do
		automations[i]()
	end
end

function macbeth:registerAutomations()
	for file in hs.fs.dir(userAutomationsPath) do
		-- The files we're interested in have alphanumeric extensions.
		local pattern = "(.*)%.([%w]+)$"
		local name, extension = string.match(file, pattern)
		if name and macbeth.automationHandlers[extension] then
			local fullPath = userAutomationsPath .. "/" .. file
			-- some functions don't like paths with ~s and other such characters, so we just make them absolute.
			fullPath = hs.fs.pathToAbsolute(fullPath)
			if not registeredAutomations[name] then
				registeredAutomations[name] = {}
			end
			table.insert(registeredAutomations[name], macbeth.automationHandlers[extension](fullPath))
		end		
	end
end

function macbeth:setupHotkeys() 
	for eventName, _ in pairs(registeredAutomations) do
		-- The pattern is "hotkey.", followed by a dash-separated list of modifiers,
		-- followed by a key.
		local pattern = "^hotkey.([%w-]*)-(%w*)$"
		local modifiers, key = string.match(name, pattern)
		if modifiers then
			hs.hotkey.bind(modifiers, key, function()
				macbeth.emit(eventName)
			end)
		end
	end
end

return macbeth