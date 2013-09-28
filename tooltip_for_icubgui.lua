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
gui_port = yarp.BufferedPortBottle();

--parameters
X= 0.01
Y= -0.25
Z= 0.01



name=""

function XYZhandToRoot( v0, v1, v2, theta)
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

function handToRoot( v0, v1, v2, theta)
    -- return roll-pitch-yaw representation for hand f.o.r.
        local out={}

    local c=math.cos(theta)
    local s=math.sin(theta)
    local C=1.0-c

    out[0]=math.atan2(v0*s-v1*v2*C,1-(v0*v0+v2*v2)*C) -- roll / bank
    out[1]=math.asin(v0*v1*C+v2*s) -- pitch / attitude
    out[2]=math.atan2(v1*s-v0*v2*C, 1-(v1*v1+v2*v2)*C)   -- yaw / heading
    return out
end

function closePorts()
    rpcSniffer:close();
    cartEEF:close();
    gui_port:close();
end


ret = rpcSniffer:open("/tooltipPlotter/rpcSniff:i");
rpcSniffer:setStrict(true)
ret = ret and cartEEF:open("/tooltipPlotter/eef:i");
ret = ret and gui_port:open("/tooltipPlotter/traj:o");

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

    local xtip =0.0
    local ytip =0.0
    local ztip=0.0
    local cmd= rpcSniffer:read(false)
    if cmd
    then
        local actualCmd=cmd:get(1):asList() -- could also check that cmd:get(0) is a "out"
        if actualCmd:get(0):asString() == "grasp"
        then
                --should check size also..
            local bInitialCmd=gui_port:prepare()
            bInitialCmd:clear()
            bInitialCmd:addString("trajectory")
            name=actualCmd:get(1):asString()
            bInitialCmd:addString(name) --name
            bInitialCmd:addString("") --label
            bInitialCmd:addInt(300) --buffer
            bInitialCmd:addDouble(3.0) --persistence
            bInitialCmd:addInt(170) --R
            bInitialCmd:addInt(230) --G
            bInitialCmd:addInt(60) --B
            bInitialCmd:addDouble(0.9) --alpha
            bInitialCmd:addDouble(10) --width

            gui_port:write()
	-- actualCmd:get(2):asDouble()  this is the arm name
            X=actualCmd:get(3):asDouble()
            Y=actualCmd:get(4):asDouble()
            Z=actualCmd:get(5):asDouble()
        end
    end

    if name ~= ""
    then
        local bTraj=cartEEF:read(false)
        if bTraj
        then
            --first add point to trajectory
            local x=bTraj:get(0):asDouble()
            local y=bTraj:get(1):asDouble()
            local z=bTraj:get(2):asDouble()
            local tip=XYZhandToRoot( bTraj:get(3):asDouble(), bTraj:get(4):asDouble(), bTraj:get(5):asDouble(), bTraj:get(6):asDouble())

            local tipOnPort=gui_port:prepare()
            tipOnPort:clear()
            tipOnPort:addString("addpoint")
            tipOnPort:addString(name)
            xtip=x+tip[0]
            ytip=y+tip[1]
            ztip=z+tip[2]
            tipOnPort:addDouble(xtip*1000)
            tipOnPort:addDouble(ytip*1000)
            tipOnPort:addDouble(ztip*1000)
            gui_port:writeStrict()

            --then draw tool

            local bOutput=gui_port:prepare()
            bOutput:clear()
            bOutput:addString("object")
            bOutput:addString(name) -- name

            bOutput:addDouble(20)       --dx  dimension
            bOutput:addDouble(-Y*1000)  -- dy
            bOutput:addDouble(20)       -- dz

            bOutput:addDouble((x+xtip)/2*1000)  --px
            bOutput:addDouble((y+ytip)/2*1000)  --py
            bOutput:addDouble((z+ztip)/2*1000)  --pz

            local toolOrient=handToRoot( bTraj:get(3):asDouble(), bTraj:get(4):asDouble(), bTraj:get(5):asDouble(), -bTraj:get(6):asDouble())
            --print("axis angle")
            --for i = 3, 7, 1 do
            --    print(bTraj:get(i):asDouble())
            --end
            --print("roll pitch yaw")
            --for i = 0, #toolOrient do
            --    print(toolOrient[i]/3.14*180)
            --end
            bOutput:addDouble(toolOrient[0]/3.14*180)  -- rx orientation
            bOutput:addDouble(toolOrient[1]/3.14*180)  -- ry
            bOutput:addDouble(toolOrient[2]/3.14*180)  -- rz

            bOutput:addInt(0)  -- r
            bOutput:addInt(0)  -- g
            bOutput:addInt(0)  -- b

            bOutput:addDouble(1.0) --alpha

            gui_port:writeStrict()
        end
    end
   yarp.Time_delay(0.05)
end

closePorts()

print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")
