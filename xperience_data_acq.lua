#!/usr/bin/lua

require("yarp")
require("icub")
yarp.Network()
icub.init()


shouldExit = false

--parameters
table_height= -0.1

thetaDraw = 90.0
thetaPush = 270.0
radius = 0.05
dist = 0.15

-- initialization
a=0.0
b=0.0
c=1.0
d=-table_height
plane=yarp.Vector(4)
print(plane:size())
plane:set(0,0.0)
plane:set(1,0.0)
plane:set(2,1.0)
plane:set(3,table_height)
side=0 --left camera


human_port = yarp.RpcServer()
--human_port = yarp.BufferedPortBottle()   -- receive commands from human friend
karmamotor_port = yarp.RpcClient()       -- send actuation commands
--gazectrlrpc_port = yarp.RpcClient()      -- query 3d position of target from 2d position
target_port=yarp.Port()                  -- get 2d position of target (left)
props = yarp.Property()
props:put("device","gazecontrollerclient")
props:put("local","/xpHelper/gaze")
props:put("remote","/iKinGazeCtrl")

ret = human_port:open("/xpHelper/human")
ret = ret and karmamotor_port:open("/xpHelper/kmotor:o")
--ret = ret and gazectrlrpc_port:open("/xpHelper/gaze:rpc")
target_port:setTimeout(2.0)
ret = ret and target_port:open("/xpHelper/target:i")

gazeDriver = yarp.PolyDriver()
gazeDriver:open(props)
gazeView=gazeDriver:viewIGazeControl();
                  local x1=yarp.Vector()
                  local px1=yarp.Vector(2)
                  px1:set(0,100)
                  px1:set(1,100)
                if gazeView:get3DPointOnPlane (side, px1, plane, x1)
                then
                   print(x1.toString())
                end
repeat
    local cmd = yarp.Bottle()
    human_port:read(cmd, true);
    local hAnsw= yarp.Bottle()
        print (cmd:toString())
    if (cmd:get(0):asString() == "draw") or (cmd:get(0):asString() == "push") 
    then
        print ("received command: ")
        print (cmd:toString())
        local target2d=yarp.Bottle()
        if target_port:read(target2d)
        then if target2d:size() >1		
             then 
                local bTtarget3d=yarp.Bottle()
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
                  px:set(0,target2d:get(0).asDouble())
                  px:set(1,target2d:get(1).asDouble())
                if gazeView:get3DPointOnPlane (side, px, plane, x)
                then 
                        if bTarget3d:size()>1 and bTarget3d:get(1):asList():size() --TODO check if and works as expected, or better, split checks
		                then
                    local target3d=bTarget3d:get(1):asList()
                            print("executing")
                            local bMotor=yarp.Bottle()
                            
                            if cmd:get(0):asString() == "draw" --[draw] cx cy cz theta radius dist. 
                	          then
                                bMotor:addString("draw")
                	    	bMotor:addDouble(target3d:get(0):asDouble())
                	    	bMotor:addDouble(target3d:get(1):asDouble())
                	    	bMotor:addDouble(table_height)
                	    	bMotor:addDouble(thetaDraw)
                	    	bMotor:addDouble(radius)
                	    	bMotor:addDouble(dist)
                            end
                            if cmd:get(0):asString():c_str() == "push" --[push] cx cy cz theta radius. 
                            then 
                                bMotor:addString("push")
                	    	bMotor:addDouble(target3d:get(0):asDouble())
                	    	bMotor:addDouble(target3d:get(1):asDouble())
                	    	bMotor:addDouble(table_height)
                	    	bMotor:addDouble(thetaPush)
                	    	bMotor:addDouble(radius)
                            end
                            local motorReply=yarp.Bottle()
                            karmamotor_port:write(bMotor, motorReply)

                            if motorReply:get(0):asString() == "ack"
			                then 
                                print("successful")        
                                hAnsw:addString("ack")
                            else
                                print("failed")
                                hAnsw:addString("nack")
                            end
		                else
                            print("failed")
                            hAnsw:addString("nack")
                        end
		            else
                        print("failed")
                        hAnsw:addString("nack")
                    end
		        else
                    print("failed")
                    hAnsw:addString("nack")
                end
            print("failed")
            hAnsw:addString("nack")
        end
    elseif cmd:get(0):asString() == "quit"
    then shouldExit=true
                    print("quitting")
                    hAnsw:addString("ack")
    else
            print("failed")
            hAnsw:addString("nack")
    end
    human_port:reply(hAnsw)
until shouldExit ~= false

gazeDriver:close()
karmamotor_port:close()
target_port:close()
human_port:close()
print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")
