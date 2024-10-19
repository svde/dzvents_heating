return {
	active = true,
	on = {
		devices = {
-- temp sensors
			't_ext', 'TH Front door',
-- setpoints
			'H/C', 'H Front door',
-- heatpump control
            'Heatpump cooling', 'Heatpump heating',
-- switches
			'Floor frontdoor'
		},
        variables = { 'hph_delayed_on' }
	},
	execute = function(dz, iteem)

		hco = dz.devices('H/C')
		hpc = dz.devices('Heatpump cooling')
		hph = dz.devices('Heatpump heating')
		hysteresis_h = 0
		hysteresis_l = 0
		t_ext = dz.devices('t_ext')

		sp_h = dz.devices('H Front door')
		rv = dz.devices('Floor frontdoor')
		temp = dz.devices('TH Front door')

		dz.log('dz.variables(hph_delayed_on).value ' .. dz.variables('hph_delayed_on').value)

		if hco.state == 'Cooling' then
            dz.log('Cooling')
		elseif hco.state == 'Heating' then
-- Turning on - Secondary floor, may only be activated if hph.state == 'On' / turning on.
			if (dz.variables('hph_delayed_on').value == 1 or hph.state == 'On') and temp.temperature < (sp_h.setPoint + hysteresis_h) then
-- Control Valve
				if rv.state == 'Off' then
					dz.log('### rv.switchOn 1 ###')
					rv.switchOn()
				end
-- Turning Off
-- Frost protection, open all valves
			elseif dz.variables('hph_delayed_on').value == 0 and hph.state == 'Off' and t_ext.temperature < 2.1 then
				dz.log('### dz.variables(hph_delayed_on).value == 0 and hph.state == Off and t_ext.temperature < 2.1 ###')
				if rv.state == 'Off' then
					dz.log('### rv.switchOn 2 ###')
					rv.switchOn()
				end
			elseif rv.state == 'On' then
				dz.log('### rv.switchOff 1 ###')
				rv.switchOff()
			end
    	elseif hco.state == 'Off' then
-- Frost protection, open all valves
		    if t_ext.temperature < 2.1 and rv.state == 'Off' then
                rv.switchOn()
            elseif t_ext.temperature >= 2.1 and rv.state == 'On' then
                rv.switchOff()
            end
        elseif hco.state == 'Manual' then
            dz.log('Manual')
        end
    end
}