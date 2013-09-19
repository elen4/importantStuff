#!/usr/bin/lua

require("yarp")

yarp.Network()


shouldExit = false

--parameters
table_height= -0.12

thetaDraw = 90.0
thetaPush = 270.0
radius = 0.05
dist = 0.15

-- initialization
a=0.0
b=0.0
c=1.0
d=-table_height
--plane=yarp.Bottle()
--plane:addDouble(0.0)
--plane::addDouble(0.0)
--plane::addDouble(1.0)
--plane::addDouble(table_height)

human_port = yarp.RpcServer()
--human_port = yarp.BufferedPortBottle()   -- receive commands from human friend
karmamotor_port = yarp.RpcClient()       -- send actuation commands
gazectrlrpc_port = yarp.RpcClient()      -- query 3d position of target from 2d position
target_port=yarp.Port()                  -- get 2d position of target (left)

ret = human_port:open("/xpHelper/human")
ret = ret and karmamotor_port:open("/xpHelper/kmotor:o")
ret = ret and gazectrlrpc_port:open("/xpHelper/gaze:rpc")
target_port:setTimeout(2.0)
ret = ret and target_port:open("/xpHelper/target:i")

repeat
    local cmd = yarp.Bottle()
    human_port:read(cmd, true);
    local hAnsw= yarp.Bottle()
    if (cmd:get(0):asString() == "draw") or (cmd:get(0):asString() == "push") 
    then
        print ("received command: ")
        print (cmd:toString())
        local target2d=yarp.Bottle()
        if target_port:read(target2d)
        then if target2d:size() >1		
             then 
                local target3d=yarp.Bottle()
                local bGazeCmd=yarp.Bottle()
                bGazeCmd:addVocab("get")
                bGazeCmd:addVocab("3D")
                bGazeCmd:addVocab("proj")
                local bGazeParamList=bGazeCmd:addList()
                bGazeParamList:addVocab("left")
                bGazeParamList:addDouble(target2d:get(0).asDouble())
                bGazeParamList:addDouble(target2d:get(1).asDouble())
                bGazeParamList:addDouble(a)
                bGazeParamList:addDouble(b)
                bGazeParamList:addDouble(c)
                bGazeParamList:addDouble(d)
                if gazectrlrpc_port:write(bGazeCmd, target3d)
                then 
                        if target3d:size()>2
		        then
                            print("executing")
                            local bMotor=yarp.Bottle()
                            if cmd:get(0):asString() == "draw" --[draw] cx cy cz theta radius dist. 
                	    then
                                bMotor:addVocab("draw")
                	    	bMotor:addDouble(target3d:get(0):asDouble())
                	    	bMotor:addDouble(target3d:get(1):asDouble())
                	    	bMotor:addDouble(table_height)
                	    	bMotor:addDouble(thetaDraw)
                	    	bMotor:addDouble(radius)
                	    	bMotor:addDouble(dist)
                            end
                            if cmd:get(0):asString() == "push" --[push] cx cy cz theta radius. 
                            then 
                                bMotor:addVocab("push")
                	    	bMotor:addDouble(target3d:get(0):asDouble())
                	    	bMotor:addDouble(target3d:get(1):asDouble())
                	    	bMotor:addDouble(table_height)
                	    	bMotor:addDouble(thetaPush)
                	    	bMotor:addDouble(radius)
                            end
                            local motorReply=yarp.Bottle()
                            karmamotor_port:write(bMotor, motorReply)

                            if motorReply:get(0):asVocab() == "ack"
			    then 
                                print("successful")        
                                hAnsw:addVocab("ack")
                            else
                                print("failed")
                                hAnsw:addVocab("nack")
                            end
			else
                            print("failed")
                            hAnsw:addVocab("nack")
                        end
		    else
                        print("failed")
                        hAnsw:addVocab("nack")
                    end
		else
                    print("failed")
                    hAnsw:addVocab("nack")
                end
        end
    elseif cmd:get(0):asString() == "draw"
    then shouldExit=true
    end
    human_port:write(hAnsw)
until shouldExit ~= false

print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
