-- Special Things for Fire Deparment Vehicles
--
-- @author  Grisu118
-- @date  07/01/2014
-- @version 1.1
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- @web: http://grisu118.ch or http://vertexdezign.de
-- Copyright (C) Grisu118, All Rights Reserved.
-- free for noncommerical-usage

--[[
<drl index="0>15|12" /> <!-- Day Drive light, is on when motor is started-->

<crew index="0>16|1" /> <!-- Crew, is visible when you are in the car -->

]]


FW_Additdional = {};

function FW_Additdional.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Motorized, specializations) then
		print("Warning: Specialization FW_Additdional needs the specialization Motorized.");
	end;

	return SpecializationUtil.hasSpecialization(Motorized, specializations);
end;
function FW_Additdional:load(xmlFile)
	--crew
	self.crew = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.crew#index"));
	setVisibility(self.crew, false);
	
	--drl (day Drive Light)
	self.drl = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.drl#index"));
	setVisibility(self.drl, false);

end;

function FW_Additdional:delete()
end;
function FW_Additdional:readStream(streamId, connection)
end;
function FW_Additdional:writeStream(streamId, connection)
end;

function FW_Additdional:mouseEvent(posX, posY, isDown, isUp, button)
end;
function FW_Additdional:keyEvent(unicode, sym, modifier, isDown)
end;
function FW_Additdional:update(dt)
end;
function FW_Additdional:updateTick(dt)
	if self.isMotorStarted then
		setVisibility(self.drl, true);
	else
		setVisibility(self.drl, false);
	end;
end;

function FW_Additdional:draw()
end;
function FW_Additdional:attachImplement(implement)
end;
function FW_Additdional:detachImplement(implementIndex)
end;
function FW_Additdional:onEnter()
	setVisibility(self.crew, true);
	if self.isMotorStarted then	
		setVisibility(self.drl, true);
	else
		setVisibility(self.drl, false);
	end;
end;
function FW_Additdional:onLeave()
	setVisibility(self.crew, false);
	if self.isMotorStarted then
		setVisibility(self.drl, true);
	else			
		setVisibility(self.drl, false);
     end;
end;
