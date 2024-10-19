return {
	on = {
	    devices = { 't_ext', 'H/C', 'Heatpump heating' },
		variables = { 'hd_ki', 'hd_lr', 'hs_ki', 'hs_lr' }
	},
	execute = function(dz, item)
        t_ext = dz.devices('t_ext')
        hco = dz.devices('H/C')
		hpc = dz.devices('Heatpump cooling')
		hph = dz.devices('Heatpump heating')
		slope = 0.5

--		dz.log('@@@ devices(heat_slope).sensorValue ' .. dz.devices('heat_slope').sensorValue)

        if dz.variables('hph_delayed_off').value ~= 0 and (dz.variables('hph_delayed_off').lastUpdate.minutesAgo > dz.variables('hph_delayed_off').value or hph.state == 'Off') then
            dz.log('@@@ hph_delayed_off set 0 @@@')
            dz.variables('hph_delayed_off').set(0)
        end

        if dz.variables('hph_delayed_on').value ~= 0 and (dz.variables('hph_delayed_on').lastUpdate.minutesAgo > 5 or hph.state == 'On') then
            dz.log('@@@ hph_delayed_on set 0 @@@')
            dz.variables('hph_delayed_on').set(0)
        end

        if hco.state == 'Cooling' then
			if hph.state == 'On' then
				if  hph.lastUpdate.minutesAgo > 45 then
					hph.switchOff()
				end
    		end
        elseif hco.state == 'Heating' then
            if hpc.state == 'On' then
				if hpc.lastUpdate.minutesAgo > 45 then
					hpc.switchOff()
				end
			else
                if dz.variables('hd_ki').value ~= 0 or dz.variables('hd_lr').value ~= 0 then

-- Determine heatslope to send to heatpump
--                  hs = 0
--                  if dz.variables('hd_ki').value ~= 0 and hs < dz.variables('hs_ki').value then
--                      hs = dz.variables('hs_ki').value
--                  end
--                  if dz.variables('hd_lr').value ~= 0 and hs < dz.variables('hs_lr').value then
--                      hs = dz.variables('hs_lr').value
--                  end

--                  if hs ~= 0 and hs ~= dz.devices('heat_slope').sensorValue then
--                      dz.log('@@@ hs ' .. hs)
--                      dz.log('@@@ dz.devices(heat_slope).sensorValue ' .. dz.devices('heat_slope').sensorValue)
--                      dz.devices('heat_slope').updateCustomSensor(hs)
--                  end

-- temporary, to manually set heat slope
--                  if dz.devices('heat_slope').sensorValue ~= 0.55 then
--                      dz.log('@@@ dz.devices(heat_slope) 0.55')
--                      dz.devices('heat_slope').updateCustomSensor(0.55)
--                  end
--                  if dz.devices('heat_slope').sensorValue ~= slope then
--                      dz.log('@@@ dz.devices(heat_slope)' .. slope)
--                      dz.devices('heat_slope').updateCustomSensor(slope)
--                  end

-- Determine setpoint to send to heatpump
                    sp_room = 0
                    if dz.variables('hd_ki').value ~= 0 and sp_room < dz.devices('H Kitchen').setPoint then
                        sp_room = dz.devices('H Kitchen').setPoint
                    end
                    if dz.variables('hd_lr').value ~= 0 and sp_room < dz.devices('H Livingroom').setPoint then
                        sp_room = dz.devices('H Livingroom').setPoint
                    end
                    if sp_room ~= 0 and sp_room ~= dz.devices('t_room1_setpoint').setPoint then
                        dz.log('@@@ sp_room ' .. sp_room)
                        dz.log('@@@ dz.devices(t_room1_setpoint).setPoint ' .. dz.devices('t_room1_setpoint').setPoint)
                        dz.devices('t_room1_setpoint').updateSetPoint(sp_room)
                    end

--
                    if dz.variables('hph_delayed_on').value == 0 and hph.state == 'Off' then
                        if t_ext.temperature < 2.1 then
                            dz.log('@@@ hph.switchOn() @@@')
                            hph.switchOn()
                        else
                            dz.log('@@@ hph_delayed_on set 1 @@@')
                            dz.variables('hph_delayed_on').set(1)
                            dz.log('@@@ hph.switchOn().afterMin(4) @@@')
                            hph.switchOn().afterMin(4)
                        end
                    end
                    if dz.variables('hph_delayed_off').value ~= 0 and hph.state == 'On' then
                        dz.log('@@@ hph_delayed_off set 0 @@@')
                        dz.variables('hph_delayed_off').set(0)
                        dz.log('@@@ hph.switchOn() @@@')
                        hph.switchOn()
                    end
                else
                    if hph.state == 'On' and hph.lastUpdate.minutesAgo < 45 and dz.variables('hph_delayed_off').value == 0 then
                        dz.log('@@@ hph_delayed_off set 1 @@@')
                        dz.variables('hph_delayed_off').set(45 - hph.lastUpdate.minutesAgo)
                        dz.log('@@@ hph.switchOff 1 @@@')
--                      dz.log('@@@ hph.switchOff 1 ' 45 - hph.lastUpdate.minutesAgo ' @@@')
                        hph.switchOff().afterMin(45 - hph.lastUpdate.minutesAgo)
                    end
                    if hph.state == 'On' and hph.lastUpdate.minutesAgo >= 45 then
		        		dz.log('@@@ hph.switchOff 2 @@@')
                        hph.switchOff()
		        	end
                end
            end
		elseif hco.state == 'Off' then
			if hpc.state == 'On' and hpc.lastUpdate.minutesAgo > 45  then
				hpc.switchOff()
			elseif hph.state == 'On' and hph.lastUpdate.minutesAgo > 45 then
				hph.switchOff()
			end
        elseif hco.state == 'Manual' then
            dz.log('hpc.state manual')
        end

--      dz.log('@@@ hp dz.variables hd_ki value ' .. dz.variables('hd_ki').value)
--      dz.log('@@@ hp dz.variables hd_lr value ' .. dz.variables('hd_lr').value)
--      dz.log('@@@ hp dz.variables.hph_delayed_off ' .. dz.variables('hph_delayed_off').value)
--      dz.log('@@@ hp dz.variables.hph_delayed_on ' .. dz.variables('hph_delayed_on').value)
	end
}