return {
	active = true,
	on = {
		devices = {
-- temp sensors
            't_ext', 'TH LR',
-- setpoints
			'H Livingroom',
-- switches
            'H/C',
-- heatpump control
            'Heatpump cooling', 'Heatpump heating',
-- floors/radiators
			'Floor livingroom'
		}
	},
	data = {
		hist_lr = { history = true, maxMinutes = 40 }
	},

	execute = function(dz, item)

		t_ext = dz.devices('t_ext')
		hco = dz.devices('H/C')
		hpc = dz.devices('Heatpump cooling')
		hph = dz.devices('Heatpump heating')
		hysteresis_h = 0.1
		hysteresis_l = 0.1
--		slope = 0.5
		h_lr = dz.devices('H Livingroom')
		r_lr = dz.devices('Floor livingroom')
		t_lr = dz.devices('TH LR')

		if item.name == 'TH LR' then
            dz.log('update data.hist_lr')
            dz.data.hist_lr.add(t_lr.temperature)
        end
--		p_lr = dz.data.hist_lr.deltaSince('00:20:00', 1, 0) * 6 + t_lr.temperature
		p_lr = (dz.data.hist_lr.avg(1,6) - dz.data.hist_lr.avg(21,26)) * 6 + dz.data.hist_lr.avg(1,6)
		if p_lr == 0 then
            p_lr = t_lr.temperature
            dz.notify('t_lr sensor issue')
        end

        dz.log('lr t_ext.temperature ' .. t_ext.temperature)
        dz.log('lr dz.variables(hd_lr).value ' .. dz.variables('hd_lr').value)
        dz.log('lr dz.variables(hd_lr).lastUpdate.minutesAgo ' .. dz.variables('hd_lr').lastUpdate.minutesAgo)
        dz.log('lr dz.variables(hph_delayed_off).value ' .. dz.variables('hph_delayed_off').value)
        dz.log('lr dz.variables(hph_delayed_on).value ' .. dz.variables('hph_delayed_on').value)
        dz.log('lr dz.variables(hph_delayed_on).lastUpdate.minutesAgo ' .. dz.variables('hph_delayed_on').lastUpdate.minutesAgo)
--      dz.log('lr dz.variables(hs_lr).value ' .. dz.variables('hs_lr').value)
        dz.log('lr h_lr.setPoint ' .. h_lr.setPoint)
        dz.log('lr hph.lastUpdate.minutesAgo ' .. hph.lastUpdate.minutesAgo)
        dz.log('lr hph.state ' .. hph.state)
        dz.log('lr lr_avg0 ' .. dz.data.hist_lr.avg(0,5))
		dz.log('lr lr_avg20 ' .. dz.data.hist_lr.avg(20,25))
		dz.log('lr p_lr ' .. p_lr)
		dz.log('lr r_lr.state ' .. r_lr.state)
		dz.log('lr t_lr ' .. t_lr.temperature)
--		dz.notify('lr t_lr ' .. t_lr.temperature)

		if hco.state == 'Cooling' then
--          Need to make something here
            dz.log('lr hco.state Coolingl')
		elseif hco.state == 'Heating' then
-- Turning on - LR
--          if (t_lr.temperature < (h_lr.setPoint - hysteresis_l) or p_lr < (h_lr.setPoint - hysteresis_l)) and t_ext.temperature < 15.5 then
			if t_lr.temperature < (h_lr.setPoint - hysteresis_l) or p_lr < (h_lr.setPoint - hysteresis_l) then
                dz.log('lr heating demand')
                if dz.variables('hd_lr').value == 0 then
                    dz.log('### hd_lr set 1')
                    dz.variables('hd_lr').set(1)
			    end
				if r_lr.state == 'Off' then
					dz.log('### r_lr.switchOn() 1 ###')
					r_lr.switchOn()
				end
-- Turning off LR
--          elseif (t_lr.temperature >= (h_lr.setPoint + hysteresis_h) and p_lr >= (h_lr.setPoint + hysteresis_h)) or t_ext.temperature > 15.5 then
            elseif t_lr.temperature >= (h_lr.setPoint + hysteresis_h) and p_lr >= (h_lr.setPoint + hysteresis_h) then
                dz.log('lr no heating demand')
                if dz.variables('hd_lr').value ~= 0 then
                    dz.log('### hd_lr set 0 ###')
                    dz.variables('hd_lr').set(0)
                end
--              if t_ext.temperature < 2.1 and (hph.state == 'Off' or dz.variables('hd_lr').lastUpdate.minutesAgo < 45) then
                if t_ext.temperature < 2.1 and (hph.state == 'Off' and dz.variables('hph_delayed_on').value == 0) then
			        if r_lr.state == 'Off' then
			        	dz.log('### r_lr.switchOn 2 ###')
						r_lr.switchOn()
					end
--              elseif (hph.state == 'Off' and dz.variables('hph_delayed_on').value == 0) or (hph.state == 'On' and (dz.variables('hd_lr').lastUpdate.minutesAgo > 45 or hph.lastUpdate.minutesAgo > 45)) then
                elseif (hph.state == 'Off' and dz.variables('hph_delayed_on').value == 0) or (hph.state == 'On' and hph.lastUpdate.minutesAgo > 45) then
                    if r_lr.state == 'On' and r_lr.lastUpdate.minutesAgo > 5 then
                        dz.log('### r_lr.switchOff() 1 ###')
                        r_lr.switchOff()
                    end
                end
            else
                dz.log('lr between hysteresis')
            end

--          diff_setpoint_temp = ( h_lr.setPoint - t_lr.temperature)
--          if diff_setpoint_temp > 0.4 then        hs = 0.9    -- slope + 0.4
--          elseif diff_setpoint_temp > 0.3 then    hs = 0.8    -- slope + 0.3
--          elseif diff_setpoint_temp > 0.2 then    hs = 0.7    -- slope + 0.2
--          elseif diff_setpoint_temp > 0.1 then    hs = 0.6    -- slope + 0.1
--          elseif diff_setpoint_temp > 0 then      hs = 0.5    -- slope
--          else                                    hs = 0.4    -- slope - 0.1
--          end
                
--          if dz.variables('hs_lr').value ~= hs then
--              dz.log('### hs_lr set ' .. hs)
--              dz.variables('hs_lr').set(hs)
--          end
		elseif hco.state == 'Off' then
			if dz.variables('hph_delayed_on').value == 1 then
			    dz.log('### hph_delayed_on set 0 ###')
--				dz.variables('hph_delayed_on').set(0)
-- ToDo: figure out how to cancel turning hph on
			end
-- Frost protection, open all valves
			if t_ext.temperature < 2.1 then
				if r_lr.state == 'Off' then
					r_lr.switchOn()
				end
			elseif hpc.state == 'Off' and hpc.lastUpdate.minutesAgo > 3 and hph.state == 'Off' and hph.lastUpdate.minutesAgo > 3 then
				if r_lr.state == 'On' then
					r_lr.switchOff()
				end
			end
        elseif hco.state == 'Manual' then
            dz.log('hpc.state manual')
        end
	end
}