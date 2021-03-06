function findNestNear(entity, chunk_position)
	local search = Chunk.to_area(chunk_position)
	local spawners = entity.surface.find_entities_filtered{area = search, type = "unit-spawner"}
	if #spawners > 0 then
		return spawners[math.random(#spawners)]
	end
	if settings.global["ion-cannon-target-worms"].value then
		local worms = entity.surface.find_entities_filtered{area = search, type = "turret"}
		if #worms > 0 then
			return worms[math.random(#worms)]
		end
	end
	return false
end

script.on_event(defines.events.on_sector_scanned, function(event)
	if settings.global["ion-cannon-auto-targeting"].value then
		local radar = event.radar
		local force = radar.force
		if force.technologies["auto-targeting"].researched == true and (settings.global["ion-cannon-min-cannons-ready"].value < countIonCannonsReady(force)) then
			local target = findNestNear(radar, event.chunk_position)
			if target then
				local fired = targetIonCannon(force, target.position, radar.surface)
				if fired then
					for i, player in pairs(force.connected_players) do
						if settings.get_player_settings(player)["ion-cannon-custom-alerts"].value then
							player.add_custom_alert(target, {type = "item", name = "orbital-ion-cannon"}, {"auto-target-designated", radar.backer_name, target.position.x, target.position.y}, true)
						end
					end
				end
			end
		end
	end
end)

script.on_event(defines.events.on_biter_base_built, function(event)
	if settings.global["ion-cannon-auto-target-visible"].value then
		local base = event.entity
		for i, force in pairs(game.forces) do
			if force.technologies["auto-targeting"].researched == true and force.is_chunk_visible(base.surface, Chunk.from_position(base.position)) and (settings.global["ion-cannon-min-cannons-ready"].value < countIonCannonsReady(force)) then
				local current_tick = game.tick
				if global.auto_tick < current_tick then
					global.auto_tick = current_tick + (settings.startup["ion-cannon-heatup-multiplier"].value * 210)
					local fired = targetIonCannon(force, base.position, base.surface)
					if fired then
						for i, player in pairs(force.connected_players) do
							if settings.get_player_settings(player)["ion-cannon-custom-alerts"].value then
								player.add_custom_alert(base, {type = "item", name = "orbital-ion-cannon"}, {"ion-cannon-target-location", fired, base.position.x, base.position.y}, true)
							end
						end
						break
					end
				end
			end
		end
	end
end)
