level_index = 0
-- 8168/8192 as of 12:08pm
-- 7896/8192 as of 1:38pm
-- recovered 272 tokens 

function _init()
    title_card = 0
    titlescreen_state = 0
    titlescreen_timer = 0
    game_finished = false
    game_finished_timer = 0
    frames = 0
    seconds = 0
    minutes = 0
    hours = 0
    show_time = false
    shake = 0
    carrot_count = 0
    death_count = 0
    carrots = {}
    collected = {}
    camera_x = 0
    camera_y = 0

    player_inst = nil

    for i = 0,127 do
        for j = 0,63 do
            if mget(i,j) == 12 then
                mset(i,j,16)
                add(carrots, { x=i, y=j })
            elseif mget(i,j) == 13 then
                if mget(i,j-1) != 4 and mget(i,j-1) != 5 then mset(i,j,5) else mset(i,j,4) end
                add(carrots, { x=i, y=j })
            end
        end
    end
    add(carrots, { x=126, y=23 })

    goto_level(5)
end

function _update()

    if titlescreen_state == 0 and btn(5) then
        titlescreen_state = 1
    elseif titlescreen_state == 1 then
        if titlescreen_timer > 55 then
            titlescreen_state = 2
            for i=100,107 do for j=52,53 do mset(i,j,4) end end
            mset(103,57,36) mset(104,57,36) mset(103,58,113) mset(104,58,113)
        end
    elseif titlescreen_state == 2 or level_index > 1 then
        if not game_finished then
            frames += 1
            if frames == 30 then seconds += 1 frames = 0 end
            if seconds == 60 then minutes += 1 seconds = 0 end
            if minutes == 60 then hours += 1 minutes = 0 end
        end

        if titlescreen_timer < 130 and level_index < 3 then show_time = true 
        elseif titlescreen_timer == 130 and level_index < 3 then show_time = false end
        if consume_st_press() and titlescreen_timer > 130 then show_time = not show_time end
    end

    if titlescreen_state > 0 and level_index < 3 then titlescreen_timer += 1 end
    if game_finished then game_finished_timer += 1 end

    shake = max(shake - 1)
    infade = min(infade + 1, 60)
    title_card = max(title_card - 1)

    update_input()

    if player_inst then player_inst:update() end

    -- update objects
    for o in all(objects) do
        if o.base != player then o:update() end
        if o.destroyed then
            del(objects, o)
        end
    end

    --printh(frames .. ": RAM = " .. flr(stat(0)/20.48) .. "%")
end

function _draw()
    pal()
	cls()
	
    if shake > 0 then
		camera(camera_x - 2 + rnd(5), camera_y - 2 + rnd(5))
	else
        camera(camera_x, camera_y)
    end

    palt(0,false)
    palt(14,true)

    local level_width = level_index == 19 and 32 or 16

    --draw tileset (except walls)
    for x = mid(level_ox / 8, flr(camera_x / 8), (level_ox / 8) + level_width),mid(0, flr((camera_x + 128) / 8), (level_ox / 8) + level_width) do
        for y = mid(level_oy/8, flr(camera_y / 8), level_oy/8 + 16),mid(0, flr((camera_y + 128) / 8), (level_oy / 8) + 16) do
            local tile = mget(x, y)
            if tile != 0 and not fget(tile, 1) then spr(tile, x * 8, y * 8) end
        end
    end
    
    local bgfx = {} -- boost gfx
    local c = {} -- carrots
    local ws = nil -- warning sign message
    local tf = nil -- tutorial fish
    local splashes = {}
    local hole_with_player_in_it = nil
	for o in all(objects) do
        if o.base == boost_cloud then
            add(bgfx, o)
        elseif o.base == carrot then
            add(c, o)
        elseif o.base == warning_sign then
            ws = o
        elseif o.base == tutorial_fish then
            tf = o
        elseif o.base == hole_in_ice and o.draw_on_top then
            hole_with_player_in_it = o
        elseif o.base == splash then
            add(splashes, o)
        else
            o:draw()
        end
	end

    if #all_moving_ice > 0 then
        for o in all(all_moving_ice) do
            o:draw()
        end
    end 

    --draw walls
    for x = mid(level_ox / 8, flr(camera_x / 8), (level_ox / 8) + level_width),mid(0, flr((camera_x + 128) / 8), (level_ox / 8) + level_width) do
        for y = mid(level_oy/8, flr(camera_y / 8), level_oy/8 + 16),mid(0, flr((camera_y + 128) / 8), (level_oy / 8) + 16) do
            local tile = mget(x, y)
            if tile != 0 and fget(tile, 1) then spr(tile, x * 8, y * 8) end
        end
    end
    
    if hole_with_player_in_it then hole_with_player_in_it:draw() end

    if tf then tf:draw() end
    
    if #bgfx > 0 then
        for o in all(bgfx) do
            o:draw()
        end
    end

    if #c > 0 then
        for o in all(c) do
            o:draw()
        end
    end

    if player_inst then player_inst:draw() end

    if #splashes > 0 then
        for sp in all(splashes) do
            sp:draw()
        end
    end

    if ws then ws:draw() end

    -- titlescreen gfx
    if titlescreen_state < 2 then 
        print("x to start", camera_x + 45, camera_y + 110, 6) 
    end
    if titlescreen_state == 1 then 
        for i=-1,1 do
            if titlescreen_timer > 4 then line(860+i, 384, 850, 409, abs(i) == 1 and 10 or 0) end
            if titlescreen_timer > 6 then line(857+i, 412) end
            if titlescreen_timer > 7 then line(847+i, 432) end
            if titlescreen_timer > 8 then line(854+i, 434) end
            if titlescreen_timer > 9 then line(832+i, 460) end
        end
        if titlescreen_timer > 9 then 
            circ(831, 459, titlescreen_timer % 6 < 3 and 7 or 13, 0)
            circ(831, 459, 10, 0)
            local rx, ry = flr(rnd(2))-1, flr(rnd(2))-1
            spr((titlescreen_timer - 10) % 6 < 3 and 96 or 97, 828+rx, 456+ry) 
        end
        if titlescreen_timer > 36 then fillp(0B1010010110100101.1) rectfill(camera_x, camera_y, camera_x+128, camera_y+128, 0) fillp() end
        if titlescreen_timer > 40 then rectfill(camera_x, camera_y, camera_x+128, camera_y+128, 0) end
        return
    elseif titlescreen_state == 2 and level_index == 1 then
        spr(98,824,456) spr(99,832,456) spr(114,824,464) spr(115,832,464)
        if titlescreen_timer < 60 then fillp(0B1010010110100101.1) rectfill(camera_x, camera_y, camera_x+128, camera_y+128, 0) fillp() end
    end

    -- endscreen gfx
    if level_index == 19 and game_finished then
        -- time
        print("time:", 168, 424, 13)
        print((hours < 10 and "0" or "") .. tostring(hours), 190, 424, 13) 
        print(":", 197, 424, 13) 
        print((minutes < 10 and "0" or "") .. tostring(minutes), 200, 424, 13) 
        print(":", 207, 424, 13) 
        print((seconds < 10 and "0" or "") .. tostring(seconds), 210, 424, 13)
        -- deaths
        print("deaths:", 168, 432, 13)
        local d = tostring(death_count)
        print(d, 206 - ((#d - 1) * 2), 432, 13)
        -- carrots
        print("carrots:", 168, 440, 13)
        local c = tostring(carrot_count)
        print(c, 206 - ((#c - 1) * 2), 440, 13)
    end

    if #snowflakes > 0 then
        for flake in all(snowflakes) do
            flake:draw()
        end
    end

    if show_time then
        rectfill(camera_x + 1, camera_y + 1, camera_x + 29, camera_y + 7, 0)
        print((hours < 10 and "0" or "") .. tostring(hours), camera_x + 2, camera_y + 2, 7) 
        print(":", camera_x + 9, camera_y + 2, 7) 
        print((minutes < 10 and "0" or "") .. tostring(minutes), camera_x + 12, camera_y + 2, 7) 
        print(":", camera_x + 19, camera_y + 2, 7) 
        print((seconds < 10 and "0" or "") .. tostring(seconds), camera_x + 22, camera_y + 2, 7)
    end

    -- title cards
    if title_card > 0 and title_card <= 50  and level_index > 2 then
        local r = title_card > 8 and min(50 - title_card, 8) or title_card
        circfill(camera_x + 64, camera_y + 64, r, 0)
        if title_card > 8 and title_card < 42 then 
            level_str = level_index < 19 and tostring(level_index - 2) or "end"
            print(level_str, camera_x + 65 - (#level_str * 2), camera_y + 62, 7)
        end
    end

    -- fade out
    if player_inst and player_inst.t_level_wipe > 15 then
		local r = (player_inst.t_level_wipe - 15) / 2
		for i=0,15 do
            for j=0,15 do
                circfill(camera_x + i * 8 + 4, camera_y + j * 8 + 4, r, 0)
            end
		end
	end

    -- fade in
    if infade < 15 then
        local r = 7 - (infade / 2)
		for i=0,15 do
            for j=0,15 do
                circfill(camera_x + i * 8 + 4, camera_y + j * 8 + 4, r, 0)
            end
		end
    end
end

function approach(x, target, max_delta)
	return x < target and min(x + max_delta, target) or max(x - max_delta, target)
end

-- like sgn(), but returns 0 instead of 1 if you pass it 0
function _sgn(var)
    return var == 0 and 0 or sgn(var)
end

function psfx(id, off, len, lock)
	if sfx_timer <= 0 or lock then
		sfx(id, 3, off, len)
		if lock then sfx_timer = lock end
	end
end

function normalize(x, y)
    local ucx = 0
    local ucy = 0
    local mag = sqrt(x * x + y * y) -- original magnitude
    if x * y != 0 then 
        ucx =  x / mag
        ucy = y / mag
    else
        if x != 0 then ucx = sgn(x) end
        if y != 0 then ucy = sgn(y) end
    end
    return ucx, ucy, mag
end

function denormalize(ucx, ucy, mag)
    local uca = atan2(ucx, ucy)
    uca = flr(uca*1000)/1000
    return cos(uca) * mag, sin(uca) * mag
end

-- rotate
function rot(start, increment, target)
    local r = start + increment
    if increment > 0 then
        if target < start then 
            target += 1
        end
        if r > target then r = target end
        if r >= 1 then r -= 1 end
    else -- increment < 0 
        if target > start then 
            target -= 1
        end
        if r < target then r = target end
        if r < 0 then r += 1 end
    end
    return r
end

-- values returned by atan2(x,y)
--  >   0
--  ^> .125
--  ^  .25
-- <^  .375
-- <   .5
-- <v  .625
--  v  .75
--  v> .875