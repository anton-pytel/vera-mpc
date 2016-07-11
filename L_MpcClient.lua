module("L_MpcClient", package.seeall)

MPCCTRL_SERVICE = "urn:demo-micasaverde-com:serviceId:MpcControl1"
local DEVICE_ID
local PARENT_DEVICE
local DEVICE_TYPE = "urn:demo-micasaverde-com:device:MpcClient:1"
local MSG_CLASS = "MpcClient"

local DEBUG_MODE = true
local taskHandle = -1

local TASK_ERROR = 2
local TASK_ERROR_PERM = -2
local TASK_SUCCESS = 4
local TASK_BUSY = 1

local function log(text, level)
	luup.log(string.format("%s: %s", MSG_CLASS, text), (level or 50))
end

local function debug(text)
	if (DEBUG_MODE) then
		log("debug: " .. text)
	end
end

local function task(text, mode)
	luup.log("task " .. text)
	if (mode == TASK_ERROR_PERM) then
		taskHandle = luup.task(text, TASK_ERROR, MSG_CLASS, taskHandle)
	else
		taskHandle = luup.task(text, mode, MSG_CLASS, taskHandle)

		-- Clear the previous error, since they're all transient
		if (mode ~= TASK_SUCCESS) then
			luup.call_delay("clearTask", 30, "", false)
		end
	end
end

--
-- Has to be "non-local" in order for MiOS to call it
--
function clearTask()
	task("Clearing...", TASK_SUCCESS)
end


-- function is called after startup to check input data
function startupDeferred()
    -- check model
	local empty = luup.variable_get(MPCCTRL_SERVICE, "transferFunction", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		--
		-- Set the variable so that it appears in the Device/Advanced list
		--
		luup.variable_set(MPCCTRL_SERVICE, "transferFunction", "", PARENT_DEVICE)
		luup.variable_set(MPCCTRL_SERVICE, "transFuncType", "zspace", PARENT_DEVICE)
		luup.variable_set(MPCCTRL_SERVICE, "inputDelay", "0", PARENT_DEVICE)
		local msg = "Mathematical model is empty. Set in Dialog, and Save/Reload."
		task(msg, TASK_ERROR_PERM)
		return
	end
	-- check url
	empty = luup.variable_get(MPCCTRL_SERVICE, "mpcUrl", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		--
		-- Set the variable so that it appears in the Device/Advanced list
		--
		luup.variable_set(MPCCTRL_SERVICE, "mpcUrl", "http://192.168.1.191:8080/c-a-a-s/rest/mpccontrollers", PARENT_DEVICE)
		local msg = "Check CAAS connection."
		task(msg, TASK_ERROR_PERM)
		return
	end	
	-- check setpoint
	empty = luup.variable_get(MPCCTRL_SERVICE, "setpoint", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		--
		-- Set the variable so that it appears in the Device/Advanced list
		--
		luup.variable_set(MPCCTRL_SERVICE, "setpoint", "", PARENT_DEVICE)
		local msg = "Set the setpoint value of controlled system"
		task(msg, TASK_ERROR_PERM)
		return
	end	
	-- check samplePeriod
	empty = luup.variable_get(MPCCTRL_SERVICE, "samplePeriod", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		--
		-- Set the variable so that it appears in the Device/Advanced list
		--
		luup.variable_set(MPCCTRL_SERVICE, "samplePeriod", "", PARENT_DEVICE)
		local msg = "Set the samplePeriod value of controlled system"
		task(msg, TASK_ERROR_PERM)
		return
	end	
	-- check controlled device
	empty = luup.variable_get(MPCCTRL_SERVICE, "ctrlDeviceId", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		--
		-- Set the variable so that it appears in the Device/Advanced list
		--
		--luup.variable_set(MPCCTRL_SERVICE, "ctrlDeviceId", "137", PARENT_DEVICE)
		--luup.variable_set(MPCCTRL_SERVICE, "ctrlServiceId", "serviceId=urn:upnp-org:serviceId:SwitchPower1", PARENT_DEVICE)
		--luup.variable_set(MPCCTRL_SERVICE, "ctrlActionType", "SetTarget", PARENT_DEVICE)
		--luup.variable_set(MPCCTRL_SERVICE, "ctrlVariableType", "newTargetValue", PARENT_DEVICE)
		
		local msg = "Choose device to be controlled"
		task(msg, TASK_ERROR_PERM)
		return
	end		
     -- check measuring device
	empty = luup.variable_get(MPCCTRL_SERVICE, "mesDeviceId", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		--
		-- Set the variable so that it appears in the Device/Advanced list
		--
		--luup.variable_set(MPCCTRL_SERVICE, "mesDeviceId", "203", PARENT_DEVICE)
		--luup.variable_set(MPCCTRL_SERVICE, "mesServiceId", "urn:micasaverde-com:serviceId:LightSensor1", PARENT_DEVICE)
		--luup.variable_set(MPCCTRL_SERVICE, "mesVariableType", "CurrentLevel", PARENT_DEVICE)
		
		local msg = "Choose device to be controlled"
		task(msg, TASK_ERROR_PERM)
		return
	end		
end

-- this runs when the first time device is created
function initialize(parentDevice)
    PARENT_DEVICE = parentDevice
    
	log("#" .. tostring(parentDevice) .. " starting up with id " .. luup.devices[parentDevice].id)

	--
	-- Set variables for  override, only "set" these if they aren't already set
	-- to force these Variables to appear in Vera's Device list.
	--
	if (luup.variable_get(MPCCTRL_SERVICE, "bypass", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "bypass", "1", parentDevice)
	end

	if (luup.variable_get(MPCCTRL_SERVICE, "transferFunction", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "transferFunction", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "transFuncType", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "transFuncType", "zspace", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "mpcUrl", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "mpcUrl", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "mpcid", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "mpcid", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "stepid", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "stepid", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "stepTimestampStart", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "stepTimestampStart", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "stepTimestampEnd", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "stepTimestampEnd", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "setpoint", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "setpoint", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "samplePeriod", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "samplePeriod", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "inputDelay", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "inputDelay", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "measuredValue", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "measuredValue", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "ctrlDeviceId", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "ctrlDeviceId", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "ctrlServiceId", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "ctrlServiceId", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "ctrlActionType", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "ctrlActionType", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "ctrlVariableType", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "ctrlVariableType", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "mesDeviceId", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "mesDeviceId", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "mesServiceId", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "mesServiceId", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "mesVariableType", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "mesVariableType", "", parentDevice)
	end	
	if (luup.variable_get(MPCCTRL_SERVICE, "computedY", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "computedY", "", parentDevice)
	end		
	if (luup.variable_get(MPCCTRL_SERVICE, "computedU", parentDevice) == nil) then
		luup.variable_set(MPCCTRL_SERVICE, "computedU", "", parentDevice)
	end		
	
	--
	-- Do this deferred to avoid slowing down startup processes.
	--
	startupDeferred()
end

function setMpc(xTransFunc, xTransFuncType, xSamplePeriod, xInputDelay)

	-- checks
	local empty = luup.variable_get(MPCCTRL_SERVICE, "ctrlDeviceId", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Controlled device id is null"
		task(msg, TASK_ERROR_PERM)
		return
	end		
	empty = luup.variable_get(MPCCTRL_SERVICE, "ctrlServiceId", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Controlled device service is null"
		task(msg, TASK_ERROR_PERM)
		return
	end		
	empty = luup.variable_get(MPCCTRL_SERVICE, "ctrlActionType", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Controlled device action is null"
		task(msg, TASK_ERROR_PERM)
		return
	end	
	empty = luup.variable_get(MPCCTRL_SERVICE, "ctrlVariableType", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Controlled device Variable id is null"
		task(msg, TASK_ERROR_PERM)
		return
	end	
	empty = luup.variable_get(MPCCTRL_SERVICE, "mesDeviceId", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Measured device id is null"
		task(msg, TASK_ERROR_PERM)
		return
	end	
	empty = luup.variable_get(MPCCTRL_SERVICE, "mesServiceId", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Measured device service  is null"
		task(msg, TASK_ERROR_PERM)
		return
	end		
	empty = luup.variable_get(MPCCTRL_SERVICE, "mesVariableType", PARENT_DEVICE)
	if (empty == nil or empty == "" ) then
		local msg = "Measured device Variable  is null"
		task(msg, TASK_ERROR_PERM)
		return
	end		
	if (xTransFunc == nil or xTransFunc == "" ) then
		local msg = "Transfer function is null"
		task(msg, TASK_ERROR_PERM)
		return
	end		
	if (xTransFuncType == nil or xTransFuncType == "" ) then
		local msg = "Transfer function type is null"
		task(msg, TASK_ERROR_PERM)
		return
	end	
	if (xSamplePeriod == nil or xSamplePeriod == "" ) then
		local msg = "Sample period is null"
		task(msg, TASK_ERROR_PERM)
		return
	end		
	if (xInputDelay == nil or xInputDelay == "" ) then
		local msg = "Input delay is null"
		task(msg, TASK_ERROR_PERM)
		return
	end				

   local url = luup.variable_get(MPCCTRL_SERVICE, "mpcUrl", PARENT_DEVICE)
   local payload = [[
   {
    "CtlSys": {
        "Tfcn" : {
            "SysString": "#tranffunc",
            "SysType": "#transfunctype"
        },
		"InputDelay": #inputdelay,
		"SamplingTime": #samplingtime
    }
   }
   ]] 
   payload = string.gsub(payload,"#tranffunc",xTransFunc)
   payload = string.gsub(payload,"#transfunctype",xTransFuncType)
   payload = string.gsub(payload,"#inputdelay",xInputDelay)
   payload = string.gsub(payload,"#samplingtime",xSamplePeriod)
   local code, resp = sendJsonRequest(url, payload)	
   debug("code: " .. tostring(code))
   debug("response: " .. resp)
   if code~=200 then
		local msg = "Failed to load controller"
		task(msg, TASK_ERROR_PERM)
		return 
   end
   local ctrl=parseJson(resp)
	
   local mpcid = ctrl.Mpcid
   luup.variable_set(MPCCTRL_SERVICE, "transferFunction", xTransFunc, PARENT_DEVICE)
   luup.variable_set(MPCCTRL_SERVICE, "transFuncType", xTransFuncType, PARENT_DEVICE)
   luup.variable_set(MPCCTRL_SERVICE, "inputDelay", xInputDelay, PARENT_DEVICE)
   luup.variable_set(MPCCTRL_SERVICE, "samplePeriod", xSamplePeriod, PARENT_DEVICE)
	
	-- Resubmit the refreshCache job, unless the period==0 (disabled/manual)
	debug("timer for nextStep set in " .. tostring(xSamplePeriod) .. " sec.")
	return mpcid;
	
end

function doStep ()
	 local yComputedY, yComputedU = mpcctrl.getNextStep()
	 if yComputedU then
		 luup.variable_set(MPCCTRL_SERVICE, "computedY", yComputedY, PARENT_DEVICE)
		 luup.variable_set(MPCCTRL_SERVICE, "computedU", yComputedU, PARENT_DEVICE)
	 end
end

function getNextStep()

	local bypass = luup.variable_get(MPCCTRL_SERVICE, "bypass", PARENT_DEVICE)
	local samplePeriod =luup.variable_get(MPCCTRL_SERVICE, "samplePeriod", PARENT_DEVICE)
	local lU = 0
	local lY = 0
	luup.variable_set(MPCCTRL_SERVICE, "stepTimestampStart", createDate(os.date('*t')), PARENT_DEVICE)
	
	if bypass~="1" then
		local url = luup.variable_get(MPCCTRL_SERVICE, "mpcUrl", PARENT_DEVICE)
		local mpcid = luup.variable_get(MPCCTRL_SERVICE, "mpcid", PARENT_DEVICE)
		local lDV = luup.variable_get(MPCCTRL_SERVICE, "mesDeviceId", PARENT_DEVICE)
		local lSRV = luup.variable_get(MPCCTRL_SERVICE, "mesServiceId", PARENT_DEVICE)
		local lVAR = luup.variable_get(MPCCTRL_SERVICE, "mesVariableType", PARENT_DEVICE)
		
		local lMeasuredValue = luup.variable_get(lSRV, lVAR, tonumber(lDV))
		local setpoint = luup.variable_get(MPCCTRL_SERVICE, "setpoint", PARENT_DEVICE)
		local payload = [[{
							"CtrlStateLast": {
								"Y0": {
								  "Val": [
									#measured
								  ]
								}
							},
							"RefSig": [
								[
								  {
									"TRef": 0,
									"YRef": #setpoint
								  }
								]
							  ]	
						  }	  ]]
		payload = string.gsub(payload,"#measured",tostring(lMeasuredValue))
		payload = string.gsub(payload,"#setpoint",tostring(setpoint))				  
		local path = url .. mpcid .. "/steps"
		local code, resp = sendJsonRequest(path, payload)
		local MpcStep=parseJson(resp)
	    debug("code: " .. tostring(code))
  	    debug("response: " .. resp)
 
		if code~=200 then
			local msg = "Failed to get step"
			task(msg, TASK_ERROR_PERM)
			lU = -1
			lY = -1		
		else
			lU = MpcStep.CtrlStateNew.U0.Val[1]
			lY = MpcStep.CtrlStateNew.Y0.Val[1]	
			local lcDV = luup.variable_get(MPCCTRL_SERVICE, "ctrlDeviceId", PARENT_DEVICE)
			local lcSRV = luup.variable_get(MPCCTRL_SERVICE, "ctrlServiceId", PARENT_DEVICE)
			local lcACT = luup.variable_get(MPCCTRL_SERVICE, "ctrlActionType", PARENT_DEVICE)			
			local lcVAR = luup.variable_get(MPCCTRL_SERVICE, "ctrlVariableType", PARENT_DEVICE)
			local resultCode, resultString, job, returnArguments = luup.call_action(lcSRV, lcACT, { [ lcVAR ] = lU }, tonumber(lcDV))
			debug ("resultCode" .. resultCode)
			debug ("resultString" .. resultString)
			debug ("job" .. job)
			if (returnArguments~=nil) then
				debug ("returnArguments" .. table.concat(returnArguments))
			end
		end
    end
	luup.variable_set(MPCCTRL_SERVICE, "stepTimestampEnd", createDate(os.date('*t')), PARENT_DEVICE)
	-- Resubmit the refreshCache job, unless the period==0 (disabled/manual)
	debug("timer for nextStep set in " .. tostring(samplePeriod) .. " sec.")
	luup.call_timer("nextStep", 1, tostring(samplePeriod), "")			
	return lY, lU;
end

function setCtrlDevice(xDeviceId, xServiceId, xAction, xVariable)
	luup.variable_set(MPCCTRL_SERVICE, "ctrlDeviceId", xDeviceId, PARENT_DEVICE)
	luup.variable_set(MPCCTRL_SERVICE, "ctrlServiceId", xServiceId, PARENT_DEVICE)
	luup.variable_set(MPCCTRL_SERVICE, "ctrlActionType", xAction, PARENT_DEVICE)
	luup.variable_set(MPCCTRL_SERVICE, "ctrlVariableType", xVariable, PARENT_DEVICE)
end
function setMesDevice(xDeviceId, xServiceId, xVariable)
	luup.variable_set(MPCCTRL_SERVICE, "mesDeviceId", xDeviceId, PARENT_DEVICE)
	luup.variable_set(MPCCTRL_SERVICE, "mesServiceId", xServiceId, PARENT_DEVICE)
	luup.variable_set(MPCCTRL_SERVICE, "mesVariableType", xVariable, PARENT_DEVICE)	
end

function testStep()	
	local url = "http://192.168.1.191:8080/c-a-a-s/rest/mpccontrollers/"
	local mpcid = "574d8abd4dc621282472c9b3"
	local payload = [[{
						"CtrlStateLast": {
							"Y0": {
							  "Val": [
								#measured
							  ]
							}
						},
						"RefSig": [
							[
							  {
								"TRef": 0,
								"YRef": #setpoint
							  }
							]
						  ]	
					  }	  ]]
	payload = string.gsub(payload,"#measured",20)
	payload = string.gsub(payload,"#setpoint",21)	
    local path = url .. mpcid .. "/steps"
    local code, resp = sendJsonRequest(path, payload)
    local MpcStep=parseJson(resp)
    luup.log("step")
    luup.log(MpcStep.Stepid)
    luup.log("u")
    luup.log(MpcStep.CtrlStateNew.U0.Val[1])
	luup.log("y")
    luup.log(MpcStep.CtrlStateNew.Y0.Val[1])
end	

function testCtrl()
	local url = "http://192.168.1.191:8080/c-a-a-s/rest/mpccontrollers/"
	local payload = [[
	{
	"CtlSys": {
		"Tfcn" : {
			"SysString": "#tranffunc",
			"SysType": "#transfunctype"
		}
	},
	"InputDelay": #inputdelay,
	"SamplingTime": #samplingtime
	}
	]] 
	payload = string.gsub(payload,"#tranffunc","((z^-1*(1.04 + 0.23 * z^-1)))/((1-0.99*z^-1)*(1-5.1e-3*z^-1))")
	payload = string.gsub(payload,"#transfunctype","zspace")
	payload = string.gsub(payload,"#inputdelay","0")
	payload = string.gsub(payload,"#samplingtime","15")
	local code, resp = sendJsonRequest(url, payload)	
	
	if code~=200 then
		luup.log("Failed to load controller")
	
	end
	local ctrl=parseJson(resp)

	local mpcid = ctrl.Mpcid
	luup.log("mpcid")
	luup.log(mpcid)
end


function parseJson(xString)
  JSON = (loadfile "/usr/lib/lua/JSON.lua")()   
  local object = JSON:decode(xString)
  return object
 end

function sendJsonRequest(xUrl,xPayload)
  --local path = "http://192.168.1.191:8080/c-a-a-s/rest/mpccontrollers/574d8abd4dc621282472c9b3/steps"
  local path = xUrl
  package.loaded.http = nil
  local http = require("socket.http")
  package.loaded.ltn12 = nil
  local ltn12 = require("ltn12")
  --local payload = [[ {"key":"My Key","name":"My Name","description":"The description","state":1} ]]
  local payload = xPayload
 
  local response_body = { }
  local res, code, response_headers, status = http.request
  {
    url = path,
    method = "POST",
    headers =
    {
      --["Authorization"] = "Maybe you need an Authorization header?", 
      ["Content-Type"] = "application/json",
      ["Content-Length"] = payload:len()
    },
    source = ltn12.source.string(payload),
    sink = ltn12.sink.table(response_body)
  }
  package.loaded.http = nil
  package.loaded.ltn12 = nil
  collectgarbage("collect")  
  return code, table.concat(response_body)
end

function createDate(xDateTime)
	local t = xDateTime
	return t.year .. string.format( "%02d", t.month ) ..string.format( "%02d", t.day )  .. string.format( "%02d", t.hour )  .. string.format( "%02d", t.min )  .. string.format( "%02d", t.sec ) 
end

function testval()
	PARENT_DEVICE = 222
	MPCCTRL_SERVICE = "urn:demo-micasaverde-com:serviceId:MpcControl1"
	local lDV = luup.variable_get(MPCCTRL_SERVICE, "mesDeviceId", PARENT_DEVICE)
	luup.log(lDV)
	local lSRV = luup.variable_get(MPCCTRL_SERVICE, "mesServiceId", PARENT_DEVICE)
	luup.log(lSRV)
	local lVAR = luup.variable_get(MPCCTRL_SERVICE, "mesVariableType", PARENT_DEVICE)
	luup.log(lVAR)
	local lMeasuredValue = luup.variable_get(lSRV, lVAR, tonumber(lDV))
	--local lMeasuredValue = luup.variable_get("urn:micasaverde-com:serviceId:LightSensor1", "CurrentLevel", 203)
	local setpoint = luup.variable_get(MPCCTRL_SERVICE, "setpoint", PARENT_DEVICE)
	luup.log("mes: ")
	luup.log(lMeasuredValue)
	luup.log("sp: " .. setpoint)
end
function testval2()
	PARENT_DEVICE = 222
	MPCCTRL_SERVICE = "urn:demo-micasaverde-com:serviceId:MpcControl1"
	local lcDV = luup.variable_get(MPCCTRL_SERVICE, "ctrlDeviceId", PARENT_DEVICE)
	luup.log(lcDV)
	local lcSRV = luup.variable_get(MPCCTRL_SERVICE, "ctrlServiceId", PARENT_DEVICE)
	luup.log(lcSRV)
	local lcACT = luup.variable_get(MPCCTRL_SERVICE, "ctrlActionType", PARENT_DEVICE)			
	luup.log(lcACT)
	local lcVAR = luup.variable_get(MPCCTRL_SERVICE, "ctrlVariableType", PARENT_DEVICE)
	luup.log(lcVAR)
	
	--local resultCode, resultString, job, returnArguments = luup.call_action(lcSRV, lcACT, { lcVAR = 50 }, tonumber(lcDV))
	local resultCode, resultString, job, returnArguments = luup.call_action("urn:upnp-org:serviceId:Dimming1", "SetLoadLevelTarget", { ["newLoadlevelTarget"] = 100 }, tonumber(169))
	
	luup.log ("resultCode" .. resultCode)
	luup.log ("resultString" .. resultString)
	luup.log ("job" .. job)
	if ( returnArguments ~= nil ) then
		luup.log ("returnArguments" .. table.concat(returnArguments))
	end
end
--testval2()
--TODO: osetrit chybove stavy zo servera
