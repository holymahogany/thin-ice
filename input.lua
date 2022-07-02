input_x = 0
axis_x_turned = false
prev_x = 0
input_y = 0
axis_y_turned = false
prev_y = 0

left_pressed = false
left_presed_contig = false
right_pressed = false
right_presed_contig = false
up_pressed = false
up_pressed_contig = false
down_pressed = false
down_pressed_contig = false

-- super boost
sb_pressed = false
sb_pressed_contig = false

-- toggle show_time
st_pressed = false
st_presed_contig = false

function update_input()
    -- x axis
	prev_x = input_x
	if btn(0) then --pressing left
		if btn(1) then --also pressing right
            if axis_x_turned then
				input_x = prev_x
			else --this runs the first update that left and right are pressed simultaneously
                axis_x_turned = true 
                input_x = -prev_x
			end
		else -- only pressing left
            axis_x_turned = false
            input_x = -1
		end
	elseif btn(1) then --only pressing right
        axis_x_turned = false
        input_x = 1
	else --not pressing left or right
        axis_x_turned = false
        input_x = 0
    end

    -- y axis
    prev_y = input_y
	if btn(2) then --pressing up
		if btn(3) then --also pressing down
            if axis_y_turned then
				input_y = prev_y
			else --this runs the first update that up and right are pressed simultaneously
                axis_y_turned = true 
                input_y = -prev_y
			end
		else -- only pressing up
            axis_y_turned = false
            input_y = -1
		end
	elseif btn(3) then --only pressing down
        axis_y_turned = false
        input_y = 1
	else --not pressing up or down
        axis_y_turned = false
        input_y = 0
    end

	-- one-off arrow key presses
	if btn(0) and not left_pressed and not left_pressed_contig then 
		left_pressed = true 
		left_pressed_contig = true
	elseif not btn(0) then 
		left_pressed = false 
		left_pressed_contig = false
	end
	if btn(1) and not right_pressed and not right_pressed_contig then 
		right_pressed = true 
		right_pressed_contig = true
	elseif not btn(1) then 
		right_pressed = false 
		right_pressed_contig = false
	end
	if btn(2) and not up_pressed and not up_pressed_contig then 
		up_pressed = true 
		up_pressed_contig = true
	elseif not btn(2) then 
		up_pressed = false 
		up_pressed_contig = false
	end
	if btn(3) and not down_pressed and not down_pressed_contig then 
		down_pressed = true 
		down_pressed_contig = true
	elseif not btn(3) then 
		down_pressed = false 
		down_pressed_contig = false
	end

	-- super boost (pressing x/v/m)
	if btn(5) and not sb_pressed and not sb_pressed_contig then 
		sb_pressed = true 
		sb_pressed_contig = true
	elseif not btn(5) then 
		sb_pressed = false 
		sb_pressed_contig = false
	end

	-- toggle show_time (pressing z/c/n)
	if btn(4) and not st_pressed and not st_pressed_contig then 
		st_pressed = true 
		st_pressed_contig = true
	elseif not btn(4) then 
		st_pressed = false 
		st_pressed_contig = false
	end
end

function consume_left_press()
	local val = left_pressed
	left_pressed = false
	return val 
end

function consume_right_press()
	local val = right_pressed
	right_pressed = false
	return val 
end

function consume_up_press()
	local val = up_pressed
	up_pressed = false
	return val 
end

function consume_down_press()
	local val = down_pressed
	down_pressed = false
	return val 
end

function consume_sb_press()
	local val = sb_pressed
	sb_pressed = false
	return val 
end

function consume_st_press()
	local val = st_pressed
	st_pressed = false
	return val 
end