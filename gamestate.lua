function goto_level(index)
    level_index = index
    titlescreen_state = level_index > 1 and 2 or 0
    title_card = 70

    -- start music
    --[[local level_music = level_index > 2 and 3 or 0
    if current_music != level_music and level_music then
		current_music = level_music
		music(level_music)
	end]]
    if level_index == 3 then music(2) end

    restart_level()
end

function next_level()
    level_index += 1
    title_card = 70

	goto_level(level_index)
end

function restart_level()
	objects = {}
	infade = 0

    for o in all(non_map_holes) do
        if o.formerly_cracked_ice then
            mset(o.x/8, o.y/8, 17)
        end
    end

    non_map_holes = {} 
    all_moving_ice = {}

    level_ox = 0
    level_oy = 0

    if level_index <= 2 then -- 1-2
        level_ox = 768 + (level_index - 1) * 128
        level_oy = 384
    elseif level_index <= 10 then -- 3-10
        level_ox = (level_index - 3) * 128
    elseif level_index <= 18 then -- 11-18
        level_ox = (level_index - 11) * 128
        level_oy = 128
    elseif level_index == 19 then
        level_ox = game_finished and 128 or 0
        level_oy = 384
        -- spawn player on ice and increase the time before falling through ice
        local p = create(player, game_finished and 192 or 0, 464)
        p.state = 1
        p.prev_boost.ucx, p.prev_boost.ucy = 0, 0
        p.t_motionless_on_ice = -15
    end

    -- populate objects
    for i = level_ox/8, (level_ox/8) + (level_index == 19 and 31 or 15) do
        for j = level_oy/8, (level_oy/8) + 15 do
            local t = types[mget(i,j)]
            local s = mget(i,j)
            if t then
                create(t, i*8, j*8)
            elseif s == 29 then -- player start
                create(player, i*8, j*8)
            elseif s == 15 or s == 18 or s == 30 or s == 31 then -- moving ice
                local new_hole = create(hole_in_ice, i*8, j*8)
                add(non_map_holes, new_hole)
                local new_moving_ice = create(moving_ice, i*8, j*8, s)
                if not fget(mget(i,j+1), 0) then new_moving_ice.edge = true end
                add(all_moving_ice, new_moving_ice)
                -- some levels need extra setup
                if level_index == 16 then new_moving_ice.y -= 56 
                elseif level_index == 17 then new_moving_ice.y = 120 + (new_moving_ice.y - 120 + 56) % 136 end
            end
        end
    end

    -- populate carrots
    for c in all(carrots) do
        if not collected[id(c.x, c.y)] and c.x >= level_ox/8 and c.x < (level_ox/8) + 16 and c.y >= level_oy/8 and c.y < (level_oy/8) + 16 then
            create(carrot, c.x*8, c.y*8)
        end
    end
end

--swaps pixel coordinates for map coordinates on x-axis
function tile_px(px)
    return max(level_ox / 8, min(flr(px / 8), (level_ox / 8) + (level_index == 19 and 32 or 16) - 1))
end

--swaps pixel coordinates for map coordinates on y-axis
function tile_py(py)
    return max(level_oy / 8, min(flr(py / 8), (level_oy / 8) + 16 - 1))
end

function check_non_map_holes(x,y)
    for h in all(non_map_holes) do
        if x == h.x/8 and y == h.y/8 then return true end
    end
    return false
end