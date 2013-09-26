#!/usr/bin/lua
require("yarp")
require("icub")
require("math")
yarp.Network()

-- helper script to send tooltip positions as trajectory to iCubGui
--input ports:
-- - rpc command - check for (grasp object_name X Y Z )
rpcSniffer = yarp.BufferedPortBottle();
-- - end effector trajectory 
cartEEF = yarp.BufferedPortBottle();
--output ports:
-- - trajectory for iCubGui object port
guiTraj = yarp.BufferedPortBottle();

--parameters
X= 0.01
Y= -0.25
Z= 0.01

name=""

function handToRoot( v0, v1, v2, theta)
    local out={} 

    local c=math.cos(theta)
    local s=math.sin(theta)
    local C=1.0-c
    
    local cross_or_vec0=v1*Z-v2*Y
    local cross_or_vec1=v2*X-v0*Z
    local cross_or_vec2=v0*Y-v1*X
    
    local dot_or_vec=v0*X+v1*Y+v2*Z
    
    out[0]=X*c+cross_or_vec0*s+v0*dot_or_vec*C
    out[1]=Y*c+cross_or_vec1*s+v1*dot_or_vec*C
    out[2]=X*c+cross_or_vec2*s+v2*dot_or_vec*C

--    local xs =v0*s
--    local ys =v1*s
--    local zs =v2*s
--    local xC =v0*C
--    local yC =v1*C
--    local zC =v2*C
--    local xyC=v0*yC
--    local yzC=v1*zC
 --   local zxC=v2*xC

--    R:set(0,0,v0*xC+c)
--    R:set(0,1,xyC-zs)
--    R:set(0,2,zxC+ys)
--    R:set(1,0,xyC+zs)
--    R:set(1,1,v1*yC+c)
--    R:set(1,2,yzC-xs)
--    R:set(2,0,zxC-ys)
--    R:set(2,1,yzC+xs)
--    R:set(2,2,v2*zC+c)

    return out
end


function closePorts()
    rpcSniffer:close();
    cartEEF:close();
    guiTraj:close();
end


ret = rpcSniffer:open("/tooltipPlotter/rpcSniff:i");
ret = ret and cartEEF:open("/tooltipPlotter/eef:i");
ret = ret and guiTraj:open("/tooltipPlotter/traj:o");

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
        if actualCmd:get(0):asString() == "grasp"
        then
                --should check size also..
            local bInitialCmd=guiTraj:prepare()
            bInitialCmd:addString("trajectory")
            name=actualCmd:get(1):asString()
            bInitialCmd:addString(name) --name
            bInitialCmd:addString(name) --label
            bInitialCmd:addInt(30) --buffer
            bInitialCmd:addDouble(1.5) --persistence
            bInitialCmd:addInt(170) --R
            bInitialCmd:addInt(230) --G
            bInitialCmd:addInt(60) --B
            bInitialCmd:addDouble(0.9) --alpha
            bInitialCmd:addDouble(0.01) --width

            guiTraj:write()

            X=actualCmd:get(2):asDouble()
            Y=actualCmd:get(3):asDouble()
            Z=actualCmd:get(4):asDouble()
        end
    end

    if name ~= ""
    then
        local bTraj=cartEEF:read(false)
        if bTraj
        then
            local x=bTraj:get(0):asDouble()
            local y=bTraj:get(1):asDouble()
            local z=bTraj:get(2):asDouble()
            tip=handToRoot( bTraj:get(3):asDouble(), bTraj:get(4):asDouble(), bTraj:get(5):asDouble(), bTraj:get(6):asDouble())

            local tipOnPort=guiTraj:prepare()
            tipOnPort:clear()
            tipOnPort:addString("addpoint")
            tipOnPort:addString(name)
            tipOnPort:addDouble((x+tip[0])*1000)
            tipOnPort:addDouble((y+tip[1])*1000)
            tipOnPort:addDouble((z+tip[2])*1000)

            guiTraj:write()
        end
    end
   yarp.Time_delay(0.1)
end

closePorts()

print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")
