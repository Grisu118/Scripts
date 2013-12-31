-- waterCannon
-- 
--
-- @author Grisu118
-- @version v0.9
-- @date 31.12.13
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- @web: http://grisu118.ch or http://vertexdezign.de
-- free for noncommerical-usage

  
source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua");
waterCannon = {};
  
function waterCannon.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization WaterCannon needs the specialization Fillable.");
	end;
	if not SpecializationUtil.hasSpecialization(WaterTrailer, specializations) then
		print("Warning: Specialization WaterCannon needs the specialization WaterTrailer.");
	end;

	return SpecializationUtil.hasSpecialization(Fillable, specializations) and SpecializationUtil.hasSpecialization(WaterTrailer, specializations);
end;
  
function waterCannon:load(xmlFile)
  
      assert(self.setIsTurnedOn == nil, "waterCannon needs to be the first specialization which implements setIsTurnedOn");
      self.setIsTurnedOn = waterCannon.setIsTurnedOn;
      self.getIsTurnedOnAllowed = waterCannon.getIsTurnedOnAllowed;
  
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
          print("Warning: No Cannon usage specified for '" .. self.configFileName.. "'. This waterCannon will not use any Cannon.");
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
  
          local CannonSound = getXMLString(xmlFile, "vehicle.CannonSound#file");
          if CannonSound ~= nil and CannonSound ~= "" then
              CannonSound = Utils.getFilename(CannonSound, self.baseDirectory);
              self.CannonSound = createSample("CannonSound");
              self.CannonSoundEnabled = false;
              loadSample(self.CannonSound, CannonSound, false);
              self.CannonSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#pitchOffset"), 1);
              self.CannonSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.CannonSound#volume"), 1);
          end;
      end;
	  
	  self.isPumpandRoll = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.CannonUsages#isPumpandRoll"),false);

  
      self.isTurnedOn = false;
      self.speedViolationMaxTime = 1000;
      self.speedViolationTimer = self.speedViolationMaxTime;
end;
  
function waterCannon:delete()
  
  
      for k,CannonValve in pairs(self.CannonValves) do
          Utils.deleteParticleSystem(CannonValve.particleSystems);
      end;
  
      if self.CannonSound ~= nil then
          delete(self.CannonSound);
      end;
end;
  
 function waterCannon:readStream(streamId, connection)
      local turnedOn = streamReadBool(streamId);

      self:setIsTurnedOn(turnedOn, true);

  end;
  
  function waterCannon:writeStream(streamId, connection)
      streamWriteBool(streamId, self.isTurnedOn);

  end;
  
  function waterCannon:readUpdateStream(streamId, timestamp, connection)
  end;
  
  function waterCannon:writeUpdateStream(streamId, connection, dirtyMask)
  end;
  
  function waterCannon:mouseEvent(posX, posY, isDown, isUp, button)
  end;
  
  function waterCannon:keyEvent(unicode, sym, modifier, isDown)
  end;
  
function waterCannon:update(dt)
  
	if self.isClient then
		if self:getIsActiveForInput() then
			if InputBinding.hasEvent(InputBinding.WATERCANNON_SWITCH) then
				self:setIsTurnedOn(not self.isTurnedOn);
			end;
		end;
	end;
  
end;
  
function waterCannon:updateTick(dt)
	if self.isTurnedOn then
			
		if self:doCheckSpeedLimit() and self.lastSpeed*3600 > 90 then
			self.speedViolationTimer = self.speedViolationTimer - dt;
				  		
        else
            self.speedViolationTimer = self.speedViolationMaxTime;
			stopsoundGrisu = false;
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
						hasCannon = true;
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
  
--      if self:getIsActive() then
          if self.isTurnedOn then
				
				if self.isClient then
                  if not self.CannonSoundEnabled and self:getIsActiveForSound() then
					  playSample(self.CannonSound, 0, self.CannonSoundVolume, 0);
                      setSamplePitch(self.CannonSound, self.CannonSoundPitchOffset);
                      self.CannonSoundEnabled = true;
					  
                  end;
              end;
  
              if self.fillLevel <= 0 and self.capacity ~= 0 then
                  self:setIsTurnedOn(false, true);
              end;
          else
              self.speedViolationTimer = self.speedViolationMaxTime;
          end;
--      end;
  

end;
  
function waterCannon:draw()
  
      if self.isClient then
          if self.fillLevel <= 0 and self.capacity ~= 0 then
              --g_currentMission:addExtraPrintText(g_i18n:getText("FirstFillTheTool"));
          end;
  
          if self.isTurnedOn then
				
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_WATERCANNON"), self.typeDesc), InputBinding.WATERCANNON_SWITCH);
          else
            g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_WATERCANNON"), self.typeDesc), InputBinding.WATERCANNON_SWITCH);
          end;
  
          --[[if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
              g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", tBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)), 0.07+0.022, 0.019+0.029);
         end;]]
      end;
end;
  
function waterCannon:onDetach()
      if self.deactivateOnDetach then
          waterCannon.onDeactivate(self);
      else
          waterCannon.onDeactivateSounds(self);
      end;
end;
  
function waterCannon:onLeave()
--[[      if self.deactivateOnLeave then
          waterCannon.onDeactivate(self);
      else
          waterCannon.onDeactivateSounds(self);
      end;]]
end;
function waterCannon:onDeactivate()
	self.speedViolationTimer = self.speedViolationMaxTime;
	self:setIsTurnedOn(false, true)
	waterCannon.onDeactivateSounds(self);
end;
  
function waterCannon:onDeactivateSounds()
	if self.CannonSoundEnabled then
		stopSample(self.CannonSound);
		self.CannonSoundEnabled = false;
	end;
end;
  
function waterCannon:getIsTurnedOnAllowed(isTurnedOn)
	if not isTurnedOn or self.fillLevel > 0 or self.capacity == 0 then
		return true;
	end;
end;
  
function waterCannon:setIsTurnedOn(isTurnedOn, noEventSend)
	if isTurnedOn ~= self.isTurnedOn then
		if self:getIsTurnedOnAllowed(isTurnedOn) then
			SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
			self.isTurnedOn = isTurnedOn;
			if self.isClient then
				for k,CannonValve in pairs(self.CannonValves) do
					Utils.setEmittingState(CannonValve.particleSystems, self.isTurnedOn);
				end;
  
				if not self.isTurnedOn and self.CannonSoundEnabled then
					stopSample(self.CannonSound);
					self.CannonSoundEnabled = false;
				end;
			end;
			self.speedViolationTimer = self.speedViolationMaxTime;
		end;
	end;
end;