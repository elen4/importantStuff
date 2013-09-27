#!/usr/bin/lua

--parameters
table_height= -0.10

thetaDraw = 90.0
radiusDraw = 0.03
thetaPush = 180.0
radiusPush = 0.1
dist = 0.15

offsetX=0.03
offsetY=0.03
offsetZ=0.0


require("yarp")
--require("icub")
yarp.Network()
--icub.init()

-- initialization
--a=0.0
--b=0.0
--c=1.0
--d=-table_height
--plane=yarp.Vector(4)

--plane:set(0,0.0)
--plane:set(1,0.0)
--plane:set(2,1.0)
--plane:set(3,table_height)
--side=0 --left camera

function closePorts()
--gazeDriver:close()
karmamotor_port:close()
target_port:close()
human_port:close()
are_port:close()
end

human_port = yarp.RpcServer()
--human_port = yarp.BufferedPortBottle()   -- receive commands from human friend
karmamotor_port = yarp.RpcClient()       -- send actuation commands
--gazectrlrpc_port = yarp.RpcClient()      -- query 3d position of target from 2d position
target_port=yarp.Port()                  -- get 2d position of target (left)
are_port = yarp.RpcClient()       -- send actuation commands
--props = yarp.Property()
--props:put("device","gazecontrollerclient")
--props:put("local","/xpHelper/gaze")
--props:put("remote","/iKinGazeCtrl")

ret = human_port:open("/xpHelper/human")
ret = ret and karmamotor_port:open("/xpHelper/kmotor:o")
ret = ret and are_port:open("/xpHelper/are:o")
--ret = ret and gazectrlrpc_port:open("/xpHelper/gaze:rpc")
target_port:setTimeout(2.0)
ret = ret and target_port:open("/xpHelper/target:i")

if(not ret)
then
  closePorts()
  os.exit()
end
shouldExit = false

--gazeDriver = yarp.PolyDriver()
--gazeDriver:open(props)
--gazeView=gazeDriver:viewIGazeControl();
--if not gazeView
--then
--closePorts()
--os.exit()
--end

repeat
    if(s_interrupted)
    then
        closePorts()
    end

    local cmd = yarp.Bottle()
    human_port:read(cmd, true);
    local hAnsw= yarp.Bottle()
        print (cmd:toString())
    if (cmd:get(0):asString() == "grasp")
    then
        if cmd:size() >4
        then
            --send "expect" command to are
            local bAre=yarp.Bottle()
            local bAreReply=yarp.Bottle()

            --bAre:addString("expect")
            --are_port:write(bAre, bAreReply) 
            --if bAreReply:get(0):asString() == "ack"
            --then 
                print("grasping successful")
                --attach the tool to karmaMotor
                local bMotor=yarp.Bottle()
                bMotor:clear()
                bMotor:addString("tool")
                bMotor:addString("attach")
                bMotor:addString(cmd:get(2):asString())
                bMotor:addDouble(cmd:get(3):asDouble())
                bMotor:addDouble(cmd:get(4):asDouble())
                bMotor:addDouble(cmd:get(5):asDouble())
                local motorReply=yarp.Bottle()
print(bMotor:toString())
                karmamotor_port:write(bMotor, motorReply)
                if motorReply:get(0):asString() == "ack"
                then 
                    print("attaching successful")
                    hAnsw:addString("ack")
                else
                    print("attaching failed")
                    hAnsw:addString("nack")
                end
          --  else
          --      print("grasping failed")
          --      hAnsw:addString("nack")
          --  end

        else
           print("grasping command had too few arguments")
           hAnsw:addString("nack")
        end
     
    elseif (cmd:get(0):asString() == "draw") or (cmd:get(0):asString() == "push") 
    then
        print ("received command: ")
        print (cmd:toString())
        local target3d=yarp.Bottle()
        if target_port:read(target3d)
        then if target3d:size() >1		
             then 
                --local bTtarget3d=yarp.Bottle()
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
                  
--local x=yarp.Vector()
--                  local px=yarp.Vector(2)
--                  px:set(0,target2d:get(0).asDouble())
--                  px:set(1,target2d:get(1).asDouble())
 --               if gazeView:get3DPointOnPlane (side, px, plane, x)
 --               then 
   --                     if bTarget3d:size()>1 and bTarget3d:get(1):asList():size() --TODO check if and works as expected, or better, split checks
	--	                then
          --          local target3d=bTarget3d:get(1):asList()
                            print("executing")
                    local bMotor=yarp.Bottle()
                    bMotor:clear()
                    if cmd:get(0):asString() == "draw" --[draw] cx cy cz theta radius dist. 
                    then
                        bMotor:addString("draw")
                        bMotor:addDouble(target3d:get(0):asDouble() + offsetX)
                        bMotor:addDouble(target3d:get(1):asDouble() + offsetY)
                        bMotor:addDouble(table_height + offsetZ)
                        bMotor:addDouble(thetaDraw)
                        bMotor:addDouble(radiusDraw)
                        bMotor:addDouble(dist)
                    end
                    if cmd:get(0):asString() == "push" --[push] cx cy cz theta radius. 
                    then 
                        bMotor:addString("push")
                        bMotor:addDouble(target3d:get(0):asDouble() + offsetX)
                        bMotor:addDouble(target3d:get(1):asDouble() + offsetY)
                        bMotor:addDouble(table_height + offsetZ)
                        bMotor:addDouble(thetaPush)
                        bMotor:addDouble(radiusPush)
                    end

                    local bTrack=yarp.Bottle()
bTrack:clear()
                    local areReply=yarp.Bottle()
                    bTrack:addString("track")
                    bTrack:addString("track")
bTrack:addString("no_sacc")
                    are_port:write(bTrack, areReply)

--                    if(areReply:get(0):asString()=="ack")


                    local motorReply=yarp.Bottle()
                    karmamotor_port:write(bMotor, motorReply)

                    if motorReply:get(0):asString() == "ack"
                    then 
                        print("action successful")        
                        hAnsw:addString("ack")
                        local bAre=yarp.Bottle()
                        local areReply=yarp.Bottle()
bAre:clear()
                        bAre:addString("home")
                        bAre:addString("head")
                        bAre:addString("arms")
                        are_port:write(bAre, areReply)
--                    if(areReply:get(0):asString()=="ack")
                    else
                        print("action failed")
                        hAnsw:addString("nack")
                    end
                else
                    print("received wrong 3d point")
                    hAnsw:addString("nack")
                end
            else
                print("did not read 3d point")
                hAnsw:addString("nack")
            end
   --     else
   --         print("failed")
   --         hAnsw:addString("nack")
   --     end
   --         print("failed")
   --         hAnsw:addString("nack")
   --     end

    elseif cmd:get(0):asString() == "quit"
    then 
        shouldExit=true
        print("quitting")
        hAnsw:addString("ack")
    else
        print("command unknown")
        hAnsw:addString("nack")
    end
    human_port:reply(hAnsw)
until shouldExit ~= false

closePorts()
--gazeDriver:close()
--karmamotor_port:close()
--target_port:close()
--human_port:close()
print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")

