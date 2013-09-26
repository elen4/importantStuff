#!/usr/bin/lua
require("yarp")
require("icub")
yarp.Network()

-- helper script to send tooltip positions as trajectory to iCubGui
--input ports:
-- - end effector trajectory 
object_port = yarp.BufferedPortBottle();
--output ports:
-- - trajectory for iCubGui object port
gui_port = yarp.BufferedPortBottle();


function closePorts()
    object_port:close();
    gui_port:close();
end


ret = object_port:open("/targetPlotter/target:i");
ret = ret and gui_port:open("/targetPlotter/target:o");

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

    local object = object_port:read(false)
    if object
    then
        local bOutput=gui_port:prepare()
        bOutput:addString("object")
        bOutput:addString("target") -- name

        bOutput:addDouble(30) --dx  dimension
        bOutput:addDouble(30)  -- dy
        bOutput:addDouble(50)  -- dz

        bOutput:addDouble(object:get(0):asDouble()*1000) --px 
        bOutput:addDouble(object:get(1):asDouble()*1000)  --py
        bOutput:addDouble(object:get(2):asDouble()*1000)  --pz

        bOutput:addDouble(0)  -- rx orientation
        bOutput:addDouble(0)   -- ry
        bOutput:addDouble(0)   --rz

        bOutput:addInt(255) -- r
        bOutput:addInt(10)  -- g
        bOutput:addInt(10)  -- b

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
