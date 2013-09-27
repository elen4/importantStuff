#!/usr/bin/lua

require("yarp")
yarp.Network()


function closePorts()
logging_port:close()
input_port:close()
output_port:close()
end

input_port = yarp.RpcServer()   -- receive commands from human friend
output_port = yarp.RpcClient()   -- forward commands
logging_port=yarp.Port()         -- send received commands [out] and replies [in]

ret = input_port:open("/xpLogger/human")
ret = ret and output_port:open("/xpLogger/forward")
ret = ret and logging_port:open("/xpLogger/log")

if(not ret)
then
  closePorts()
  os.exit()
end



while true do
    if(s_interrupted)
    then
        closePorts()
    end

    local cmd = yarp.Bottle()
    input_port:read(cmd, true)
    
    local log=yarp.Bottle()
    log:addString("out")
    local appendedCmd= log:addList() 
    appendedCmd:append(cmd)
    logging_port:write(log)
   
    local reply=yarp.Bottle()
    output_port:write(cmd, reply)
    
    log:clear()
    log:addString("in")
    local appendedReply=log:addList()
    appendedReply:append(reply)
    logging_port:write(log)
    
    input_port:reply(reply)

end

closePorts()
print("finishing")
-- Deinitialize yarp network
yarp.Network_fini()
print("finished")

