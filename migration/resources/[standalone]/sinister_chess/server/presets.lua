if not Config.PresetTables then return end

local insertedPresets = false

Citizen.CreateThread(function()
	Wait(5000)

	local presetCoords = {}
	for _, p in ipairs(Config.PresetTables) do
		local key = string.format("%.1f_%.1f_%.1f", p.coords.x, p.coords.y, p.coords.z)
		presetCoords[key] = p
	end

	MySQL.ready(function()
		MySQL.Async.fetchAll("SELECT id, x, y, z FROM chess_tables", {}, function(rows)
			if not rows then
				insertedPresets = true
				for _, preset in ipairs(Config.PresetTables) do
					local c = preset.coords
					MySQL.Async.execute(
						"INSERT INTO chess_tables (x, y, z, h, label) VALUES (@x, @y, @z, @h, @label)",
						{ ['@x'] = c.x, ['@y'] = c.y, ['@z'] = c.z, ['@h'] = c.w, ['@label'] = preset.label }
					)
					print("^5[sinister_chess] ^7Preset table added: " .. preset.label)
				end
				return
			end

			local existing = {}
			for _, row in ipairs(rows) do
				local key = string.format("%.1f_%.1f_%.1f", row.x, row.y, row.z)
				existing[key] = true
			end

			for _, preset in ipairs(Config.PresetTables) do
				local c = preset.coords
				local key = string.format("%.1f_%.1f_%.1f", c.x, c.y, c.z)
				if not existing[key] then
					MySQL.Async.execute(
						"INSERT INTO chess_tables (x, y, z, h, label) VALUES (@x, @y, @z, @h, @label)",
						{ ['@x'] = c.x, ['@y'] = c.y, ['@z'] = c.z, ['@h'] = c.w, ['@label'] = preset.label }
					)
					print("^5[sinister_chess] ^7Preset table added: " .. preset.label)
				end
			end
			insertedPresets = true
		end)
	end)
end)

RegisterCommand("checkmate_presets", function(source)
	if insertedPresets then
		print("^5[sinister_chess] ^7Preset tables already processed.")
	else
		print("^5[sinister_chess] ^7Preset tables still being inserted, check again in a moment.")
	end
	print("Preset locations:")
	for _, p in ipairs(Config.PresetTables) do
		print(string.format("  %s — vec4(%.1f, %.1f, %.1f, %.1f)", p.label, p.coords.x, p.coords.y, p.coords.z, p.coords.w))
	end
end, true)

print("^5[sinister_chess] ^7Preset loader ready — " .. #Config.PresetTables .. " Texas Checkmate locations")
