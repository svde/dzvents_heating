return {
	active = true,
	on = {
		devices = {
-- temp sensors
            't_ext',
            'TH Kitchen',
--          'TH Kitchen2',
--          'THB Kitchen',
-- setpoints
			'H Kitchen',
-- switches
            'H/C',
-- heatpump control
            'Heatpump cooling', 'Heatpump heating',
-- floors/radiators
			'Floor kitchen'
		}
	},
	data = {
		hist_ki = { history = true, maxMinutes = 40 }
	},

	execute = function(dz, item)

		t_ext = dz.devices('t_ext')
		hco = dz.devices('H/C')
		hpc = dz.devices('Heatpump cooling')
		hph = dz.devices('Heatpump heating')
		hysteresis_h = 0.1
		hysteresis_l = 0.1
--		slope = 0.4
		h_ki = dz.devices('H Kitchen')
		r_ki = dz.devices('Floor kitchen')
		t_ki = dz.devices('TH Kitchen')

        if item.name == 'TH Kitchen' then
            dz.log('update data.hist_ki')
            dz.data.hist_ki.add(t_ki.temperature)
        end
--		p_ki = dz.data.hist_ki.deltaSince('00:20:00', 1, 0) * 6 + t_ki.temperature
		p_ki = (dz.data.hist_ki.avg(1,6) - dz.data.hist_ki.avg(21,26)) * 6 + dz.data.hist_ki.avg(1,6)
        if p_ki == 0 then
            p_ki = t_ki.temperature
            dz.notify('t_ki sensor issue')
        end

        dz.log('ki t_ext.temperature ' .. t_ext.temperature)
        dz.log('ki dz.variables(hd_ki).value ' .. dz.variables('hd_ki').value)
        dz.log('ki dz.variables(hd_ki).lastUpdate.minutesAgo ' .. dz.variables('hd_ki').lastUpdate.minutesAgo)
        dz.log('ki dz.variables(hph_delayed_off).value ' .. dz.variables('hph_delayed_off').value)
        dz.log('ki dz.variables(hph_delayed_on).value ' .. dz.variables('hph_delayed_on').value)
        dz.log('ki dz.variables(hph_delayed_on).lastUpdate.minutesAgo ' .. dz.variables('hph_delayed_on').lastUpdate.minutesAgo)
--      dz.log('ki dz.variables(hs_ki).value ' .. dz.variables('hs_ki').value)
        dz.log('ki h_ki.setPoint ' .. h_ki.setPoint)
        dz.log('ki hph.lastUpdate.minutesAgo ' .. hph.lastUpdate.minutesAgo)
        dz.log('ki hph.state ' .. hph.state)
        dz.log('ki ki_avg0 ' .. dz.data.hist_ki.avg(0,5))
		dz.log('ki ki_avg20 ' .. dz.data.hist_ki.avg(20,25))
		dz.log('ki p_ki ' .. p_ki)
		dz.log('ki r_ki.state ' .. r_ki.state)
        
		if hco.state == 'Cooling' then
            dz.log('hco.state cooling')
		elseif hco.state == 'Heating' then
-- Turning on
--          if (t_ki.temperature < (h_ki.setPoint - hysteresis_l) or p_ki < (h_ki.setPoint - hysteresis_l)) and t_ext.temperature < 15.5 then
			if t_ki.temperature < (h_ki.setPoint - hysteresis_l) or p_ki < (h_ki.setPoint - hysteresis_l) then
                dz.log('ki heating demand')
                if dz.variables('hd_ki').value == 0 then
                    dz.log('### hd_ki set 1')
                    dz.variables('hd_ki').set(1)
			    end
				if r_ki.state == 'Off' then
					dz.log('### r_ki.switchOn() 1 ###')
					r_ki.switchOn()
				end
-- Turning off
--          elseif (t_ki.temperature >= (h_ki.setPoint + hysteresis_h) and p_ki >= (h_ki.setPoint + hysteresis_h)) or t_ext.temperature > 15.5 then
            elseif t_ki.temperature >= (h_ki.setPoint + hysteresis_h) and p_ki >= (h_ki.setPoint + hysteresis_h) then
                dz.log('ki no heating demand')
                if dz.variables('hd_ki').value ~= 0 then
                    dz.log('### hd_ki set 0')
                    dz.variables('hd_ki').set(0)
                end
--              if t_ext.temperature < 2.1 and (hph.state == 'Off' or dz.variables('hd_ki').lastUpdate.minutesAgo < 45) then
                if t_ext.temperature < 2.1 and (hph.state == 'Off' and dz.variables('hph_delayed_on').value == 0) then
                    if r_ki.state == 'Off' then
                        dz.log('### r_ki.switchOn 2 ###')
                        r_ki.switchOn()
                    end
--              elseif (hph.state == 'Off' and dz.variables('hph_delayed_on').value == 0) or (hph.state == 'On' and (dz.variables('hd_ki').lastUpdate.minutesAgo > 45 or hph.lastUpdate.minutesAgo > 45)) then
                elseif (hph.state == 'Off' and dz.variables('hph_delayed_on').value == 0) or (hph.state == 'On' and hph.lastUpdate.minutesAgo > 45) then
                    if r_ki.state == 'On' and r_ki.lastUpdate.minutesAgo > 5 then
                        dz.log('### r_ki.switchOff() 1 ###')
                        r_ki.switchOff()
                    end
                end
            else
                dz.log('ki between hysteresis')
            end

--          diff_setpoint_temp = ( h_ki.setPoint - t_ki.temperature)
--          if diff_setpoint_temp > 0.4 then        hs = 0.8    -- slope + 0.4
--          elseif diff_setpoint_temp > 0.3 then    hs = 0.7    -- slope + 0.3
--          elseif diff_setpoint_temp > 0.2 then    hs = 0.6    -- slope + 0.2
--          elseif diff_setpoint_temp > 0.1 then    hs = 0.5    -- slope + 0.1
--          else                                    hs = 0.4    -- slope
----        elseif diff_setpoint_temp > 0 then      hs = 0.4    -- slope
----        else                                    hs = 0.3    -- slope - 0.1
--          end

--          if (dz.variables('hs_ki').value ~= hs) then
--              dz.log('### hs_ki set ' .. hs)
--              dz.variables('hs_ki').set(hs)
--          end
		elseif hco.state == 'Off' then
		    dz.log('hco.state Off')
-- Frost protection, open all valves
			if t_ext.temperature < 2.1 then
				if r_ki.state == 'Off' then
					r_ki.switchOn()
				end
			elseif hpc.state == 'Off' and hpc.lastUpdate.minutesAgo > 3 and hph.state == 'Off' and hph.lastUpdate.minutesAgo > 3 then
				if r_ki.state == 'On' then
					r_ki.switchOff()
				end
			end
        elseif hco.state == 'Manual' then
            dz.log('hco.state Manual')
        end
	end
}