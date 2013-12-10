-- 
--
-- @author  Grisu118
-- @date  08/11/2013
-- @version 1.0
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- Copyright (C) Grisu118, All Rights Reserved.
-- free for noncommerical-usage


weight_cabel = {};

function weight_cabel.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Attachable, specializations);
end;
function weight_cabel:load(xmlFile)	
	self.cabel_1 = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.cabel_deattached#index"));
	self.cabel_2 = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.cabel_attached#index"));
	
	setVisibility(self.cabel_1, true);
	setVisibility(self.cabel_2, false);
end;

function weight_cabel:delete()
end;
function weight_cabel:readStream(streamId, connection)
end;
function weight_cabel:writeStream(streamId, connection)
end;
function weight_cabel:mouseEvent(posX, posY, isDown, isUp, button)
end;
function weight_cabel:keyEvent(unicode, sym, modifier, isDown)
end;
function weight_cabel:update(dt)
end;
function weight_cabel:updateTick(dt)	
end;

function weight_cabel:draw()
end;
function weight_cabel:onAttach(attacherVehicle)
	setVisibility(self.cabel_1, false);
	setVisibility(self.cabel_2, true);
end;
function weight_cabel:onDetach()
	setVisibility(self.cabel_1, true);
	setVisibility(self.cabel_2, false);
end;
