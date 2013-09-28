#!/usr/bin/lua
require("yarp")
require("icub")
yarp.Network()

-- helper script to send tooltip positions as trajectory to iCubGui
--input ports:
-- - rpc command - check for (draw/push object_name  )
rpcSniffer = yarp.BufferedPortBottle();
-- - end effector trajectory 
object_port = yarp.BufferedPortBottle();
--output ports:
-- - trajectory for iCubGui object port
gui_port = yarp.BufferedPortBottle();


function closePorts()
    object_port:close();
    gui_port:close();
    rpcSniffer:close();
end

function updateObjectColor()
   if name == "octopus"
   then
       R=30
       G=144
       B=255
   elseif name == "carrots"
   then
       R=255
       G=69
       B=0
   end
end

ret = object_port:open("/targetPlotter/target:i");
ret = ret and gui_port:open("/targetPlotter/target:o");
ret = ret and rpcSniffer:open("/targetPlotter/rpcSniff:i");
rpcSniffer:setStrict(true)

name=""
R=255
G=0
B=0

if not ret
then
  closePorts()
  os.exit()
end
print("finished initialization")

while true do
    if(s_interrupted)
    then
        closePorts()
    end

    local cmd= rpcSniffer:read(false)
    if cmd
    then
        local actualCmd=cmd:get(1):asList() -- could also check that cmd:get(0) is a "out"
        if (actualCmd:get(0):asString() == "draw") or (actualCmd:get(0):asString() == "push")
        then
            --remove previous object from iCubGui
            local bOutput=gui_port:prepare()
            bOutput:clear()
            bOutput:addString("delete");
            bOutput:addString(name);
            gui_port:write()
            name=actualCmd:get(1):asString()
            updateObjectColor()
        end
    end


    local object = object_port:read(false)
    if object
    then
        local bOutput=gui_port:prepare()
        bOutput:clear()
        bOutput:addString("object")
        bOutput:addString(name) -- name

        bOutput:addDouble(30) --dx  dimension
        bOutput:addDouble(30)  -- dy
        bOutput:addDouble(50)  -- dz

        bOutput:addDouble(object:get(0):asDouble()*1000) --px 
        bOutput:addDouble(object:get(1):asDouble()*1000)  --py
        bOutput:addDouble(object:get(2):asDouble()*1000)  --pz

        bOutput:addDouble(0)  -- rx orientation
        bOutput:addDouble(0)   -- ry
        bOutput:addDouble(0)   --rz

        bOutput:addInt(R) -- r
        bOutput:addInt(G)  -- g
        bOutput:addInt(B)  -- b

        bOutput:addDouble(1.0) --alpha
        gui_port:write()

    end

   yarp.Time_delay(0.1)
end

closePorts()

print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")
