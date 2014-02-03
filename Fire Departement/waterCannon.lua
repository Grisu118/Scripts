-- WaterCannon
-- 
--
-- @author Grisu118
-- @date 02/01/14
-- @version v0.91
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- @web: http://grisu118.ch or http://vertexdezign.de
-- free for noncommerical-usage

  
source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua");
WaterCannon = {};
  
function WaterCannon.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization WaterCannon needs the specialization Fillable.");
	end;
	if not SpecializationUtil.hasSpecialization(WaterTrailer, specializations) then
		print("Warning: Specialization WaterCannon needs the specialization WaterTrailer.");
	end;
	if not SpecializationUtil.hasSpecialization(Pump, specializations) then
		print("Warning: Specialization WaterCannon needs the specialization Pump.");
	end;

	return SpecializationUtil.hasSpecialization(Fillable, specializations) and SpecializationUtil.hasSpecialization(WaterTrailer, specializations) and SpecializationUtil.hasSpecialization(Pump, specializations);
end;
  
function WaterCannon:load(xmlFile)
  
	assert(self.setIsTurnedOn == nil, "WaterCannon needs to be the first specialization which implements setIsTurnedOn");
	self.setIsTurnedOn = WaterCannon.setIsTurnedOn;
	self.getIsTurnedOnAllowed = WaterCannon.getIsTurnedOnAllowed;
  
	self.CannonLitersPerSecond = {};
	local i=0;
	while true do
		local key = string.format("vehicle.CannonUsages.CannonUsage(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local fillType = getXMLString(xmlFile, key.. "#fillType");
		local litersPerSecond = getXMLFloat(xmlFile, key.. "#litersPerSecond");
		if fillType ~= nil and litersPerSecond ~= nil then
			local fillTypeInt = Fillable.fillTypeNameToInt[fillType];
			if fillTypeInt ~= nil then
				self.CannonLitersPerSecond[fillTypeInt] = litersPerSecond;
				if self.defaultCannonLitersPerSecond == nil then
					self.defaultCannonLitersPerSecond = litersPerSecond;
				end;
			else
				print("Warning: Invalid Cannon usage fill type '"..fillType.."' in '" .. self.configFileName.. "'");
			end;
		end;
		i = i+1;
	end;
	if self.defaultCannonLitersPerSecond == nil then
		print("Warning: No Cannon usage specified for '" .. self.configFileName.. "'. This WaterCannon will not use any Cannon.");
		self.defaultCannonLitersPerSecond = 0;
	end;
  
	self.CannonValves = {};
  
	if self.isClient then
		local psFile = getXMLString(xmlFile, "vehicle.CannonParticleSystem#file");
		if psFile ~= nil then
			local i=0;
			while true do
				local baseName = string.format("vehicle.CannonValves.CannonValve(%d)", i);
				local node = getXMLString(xmlFile, baseName.. "#index");
				if node == nil then
					break;
				end;
				node = Utils.indexToObject(self.components, node);
				if node ~= nil then
					local CannonValve = {};
					CannonValve.particleSystems = {};
					Utils.loadParticleSystem(xmlFile, CannonValve.particleSystems, "vehicle.CannonParticleSystem", node, false, nil, self.baseDirectory);
					table.insert(self.CannonValves, CannonValve);
				end;
				i = i+1;
			end;
		end;
  
		  
		local cannonSound = getXMLString(xmlFile, "vehicle.CannonSound#file");
		if cannonSound ~= nil and cannonSound ~= "" then
			cannonSound = Utils.getFilename(cannonSound, self.baseDirectory);
			self.cannonSound = createSample("cannonSound");
			loadSample(self.cannonSound, cannonSound, false);
			self.cannonSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#pitchOffset"), 1.0);
			self.cannonSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#pitchScale"), 0.05);
			self.cannonSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#pitchMax"), 2.0);
			self.cannonSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#volume"), 1.0);
    
			self.cannonSoundEnabled = false;
    
			self.cannonSound3DVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#volume3D"), self.cannonSoundVolume);
			self.cannonSound3DInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#innerRadius"), 10);
			self.cannonSound3DRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#radius"), 50);
    
    
			self.cannonSound3D = createAudioSource("cannonSound3D", cannonSound, self.cannonSound3DRadius, self.cannonSound3DInnerRadius, self.cannonSound3DVolume, 0);
			link(self.components[1].node, self.cannonSound3D);
			setVisibility(self.cannonSound3D, false);
   
		end;		  
	end;
	  
	self.isPumpandRoll = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.CannonUsages#isPumpandRoll"),false);

  
	self.isTurnedOn = false;
	self.speedViolationMaxTime = 1000;
	self.speedViolationTimer = self.speedViolationMaxTime;
end;
  
function WaterCannon:delete()
  
  
      for k,CannonValve in pairs(self.CannonValves) do
          Utils.deleteParticleSystem(CannonValve.particleSystems);
      end;
  
      if self.cannonSound ~= nil then
          delete(self.cannonSound);
      end;
end;
  
function WaterCannon:readStream(streamId, connection)
	local turnedOn = streamReadBool(streamId);

	self:setIsTurnedOn(turnedOn, true);

end;
  
function WaterCannon:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isTurnedOn);

end;
  
function WaterCannon:readUpdateStream(streamId, timestamp, connection)
end;
  
function WaterCannon:writeUpdateStream(streamId, connection, dirtyMask)
end;
  
function WaterCannon:mouseEvent(posX, posY, isDown, isUp, button)
end;
  
function WaterCannon:keyEvent(unicode, sym, modifier, isDown)
end;
  
function WaterCannon:update(dt)
  
	if self.isClient then
		if self:getIsActiveForInput() then
			if InputBinding.hasEvent(InputBinding.WATERCANNON_SWITCH) then
				if Pump.isTurnedOn then
					self:setIsTurnedOn(not self.isTurnedOn);
				end;
			end;
			if not Pump.isTurnedOn then
				self:setIsTurnedOn(false);
			end;
		end;
	end;
  
end;
  
function WaterCannon:updateTick(dt)
	if self.isTurnedOn then
			
		if self:doCheckSpeedLimit() and self.lastSpeed*3600 > 90 then
			self.speedViolationTimer = self.speedViolationTimer - dt;
				  		
        else
            self.speedViolationTimer = self.speedViolationMaxTime;
        end;
			
		if self.isServer then
			if self.speedViolationTimer > 0 then
				local litersPerSecond = self.CannonLitersPerSecond[self.currentFillType];
				if litersPerSecond == nil then
					litersPerSecond = self.defaultCannonLitersPerSecond;
				end;
				local usage = litersPerSecond * dt*0.001;
				
				if not self.capacity == 0 or not self:getIsHired() then
					if self.fillLevel > 0 then
						self:setFillLevel(self.fillLevel - usage, self.currentFillType);
						if not self.isPumpandRoll then
							for k,wheel in pairs(self.wheels) do
								setWheelShapeProps(wheel.node, wheel.wheelShape, 0, 999, 0);
							end;
						end;
					end;
				end;
			end;
		end;
	end;
  
--	if self:getIsActive() then
		if self.isTurnedOn then
			if self.isClient then
				if not self.CannonSoundEnabled and self:getIsActiveForSound() then
					local alpha = 0.9;
					local roundPerMinute = self.lastRoundPerMinute*alpha + (1-alpha)*(self.motor.lastMotorRpm-self.motor.minRpm);
					self.lastRoundPerMinute = roundPerMinute;
					local roundPerSecond = roundPerMinute / 60;
					
--					playSample(self.cannonSound, 0, self.cannonSoundVolume, 0);
					if self.cannonSound3D ~= nil then
						setVisibility(self.cannonSound3D, true);
					end;
					local cannonSoundPitch = math.min(self.cannonSoundPitchOffset + self.cannonSoundPitchScale*math.abs(roundPerSecond), self.cannonSoundPitchMax)
					setSamplePitch(self.cannonSound, self.cannonSoundPitch);
					if self.cannonSound3D ~= nil then
						setSamplePitch(getAudioSourceSample(self.cannonSound3D), cannonSoundPitch);
					end;
					self.CannonSoundEnabled = true;
				end;
			end;
  
			if self.fillLevel <= 0 and self.capacity ~= 0 then
				self:setIsTurnedOn(false, true);
			end;
		else
			self.speedViolationTimer = self.speedViolationMaxTime;
			if self.cannonSound3D ~= nil then
				setVisibility(self.cannonSound3D, false);
			end;
		end;
--	end;
  

end;
  
function WaterCannon:draw()
 
	if self.isClient then
		if self.fillLevel <= 0 and self.capacity ~= 0 then
			g_currentMission:addExtraPrintText(g_i18n:getText("FirstFillTheTool"));
		end;
  
		if self.isTurnedOn then
				
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_WaterCannon"), self.typeDesc), InputBinding.WATERCANNON_SWITCH);
		else
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_WaterCannon"), self.typeDesc), InputBinding.WATERCANNON_SWITCH);
		end;
		
		--TODO Make that the Warning is showing longer then half second
		if InputBinding.hasEvent(InputBinding.WATERCANNON_SWITCH) and not Pump.isTurnedOn then
			g_currentMission:addWarning(g_i18n:getText("First_turn_on_Pump") .. "/n" .. string.format(InputBinding.getKeyNamesOfDigitalAction(InputBinding.Pump_SWITCH)), 0.07+0.022, 0.019+0.029);
		end;
	end;

end;
  
function WaterCannon:onDetach()
      if self.deactivateOnDetach then
          WaterCannon.onDeactivate(self);
      else
          WaterCannon.onDeactivateSounds(self);
      end;
end;
  
function WaterCannon:onLeave()
	if self.CannonSoundEnabled then
		stopSample(self.cannonSound);
	end;
--[[      if self.deactivateOnLeave then
          WaterCannon.onDeactivate(self);
      else
          WaterCannon.onDeactivateSounds(self);
      end;]]
end;
function WaterCannon:onDeactivate()
	self.speedViolationTimer = self.speedViolationMaxTime;
	self:setIsTurnedOn(false, true)
	WaterCannon.onDeactivateSounds(self);
end;
  
function WaterCannon:onDeactivateSounds()
	if self.CannonSoundEnabled then
		stopSample(self.cannonSound);
		
		self.CannonSoundEnabled = false;
	end;
	if self.cannonSound3D ~= nil then
		setVisibility(self.cannonSound3D, false);
	end;
end;
  
function WaterCannon:getIsTurnedOnAllowed(isTurnedOn)
	if not isTurnedOn or self.fillLevel > 0 or self.capacity == 0 then
		return true;
	end;
end;
  
function WaterCannon:setIsTurnedOn(isTurnedOn, noEventSend)
	if isTurnedOn ~= self.isTurnedOn then
		if self:getIsTurnedOnAllowed(isTurnedOn) then
			SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
			self.isTurnedOn = isTurnedOn;
			if self.isClient then
				for k,CannonValve in pairs(self.CannonValves) do
					Utils.setEmittingState(CannonValve.particleSystems, self.isTurnedOn);
				end;
  
				if not self.isTurnedOn and self.CannonSoundEnabled then
					stopSample(self.cannonSound);
					self.CannonSoundEnabled = false;
				end;
			end;
			self.speedViolationTimer = self.speedViolationMaxTime;
		end;
	end;
end;