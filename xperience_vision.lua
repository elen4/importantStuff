#!/usr/bin/lua

--parameters
table_height= -0.15

-- initialization
a=0.0
b=0.0
c=1.0
d=-table_height
side=0 --left camera

require("yarp")
require("icub")
yarp.Network()
icub.init()


shouldExit = false
plane=yarp.Vector(4)
plane:set(0,a)
plane:set(1,b)
plane:set(2,c)
plane:set(3,d)

function closePorts()
  gazeDriver:close()
  target2d_port:close()
  target3d_port:close()
end


target2d_port=yarp.BufferedPortBottle()                  -- get 2d position of target (left)
target3d_port=yarp.BufferedPortBottle()                  -- write 3d position of target (left)
props = yarp.Property()
props:put("device","gazecontrollerclient")
props:put("local","/xpVision/gaze")
props:put("remote","/iKinGazeCtrl")

ret= target2d_port:open("/xpVision/target:i")
ret = ret and target3d_port:open("/xpVision/target:o")

gazeDriver = yarp.PolyDriver()
gazeDriver:open(props)
gazeView=gazeDriver:viewIGazeControl();
ret= ret and gazeView

if not ret
then
  closePorts()
  os.exit()
end
print("finished initialization")

repeat
    if(s_interrupted)
    then
        closePorts()
    end
        local target2d= target2d_port:read(false)
        if target2d	
             then  --should check size also..
                
                --local bGazeCmd=yarp.Bottle()
                --bGazeCmd:addString("get")
                --bGazeCmd:addString("3D")
                --bGazeCmd:addString("proj")
                --local bGazeParamList=bGazeCmd:addList()
                --bGazeParamList:addString("left")
                --bGazeParamList:addDouble(target2d:get(0).asDouble())
                --bGazeParamList:addDouble(target2d:get(1).asDouble())
                --bGazeParamList:addDouble(a)
                --bGazeParamList:addDouble(b)
                --bGazeParamList:addDouble(c)
                --bGazeParamList:addDouble(d)
                --if gazectrlrpc_port:write(bGazeCmd, target3d)
                
                  local x=yarp.Vector()
                  local px=yarp.Vector(2)
                 px:set(0,target2d:get(0):asDouble())
                 px:set(1,target2d:get(1):asDouble())

                if gazeView:get3DPointOnPlane (side, px, plane, x)
                then 
                      local target3d=target3d_port:prepare()
                      target3d:clear()
                      target3d:addDouble(x:get(0))
                      target3d:addDouble(x:get(1))
                      target3d:addDouble(x:get(2))
                      target3d_port:write();
                end
            end
        
   yarp.Time_delay(0.1)
until shouldExit ~= false

closePorts()

print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")
