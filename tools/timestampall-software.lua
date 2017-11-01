--- Software timestamping precision test.
--- (Used for an evaluation for a paper)
local mg     = require "moongen"
local ts     = require "timestamping"
local device = require "device"
local hist   = require "histogram"
local memory = require "memory"
local stats  = require "stats"
local timer  = require "timer"
local ffi    = require "ffi"
local eth        = require "proto.ethernet"

local PKT_SIZE = 60
local ETH_DST	= "11:12:13:14:15:16"
local warmup_iter = 1000000

function configure(parser)
	parser:description("Timestamp all - software timestamp")
	parser:argument("dev1", "Device to transmit/receive from."):convert(tonumber)
	parser:argument("dev2", "Device to transmit/receive from."):convert(tonumber)
	parser:option("-a --probe1", "Probe from dev1 every a seconds, default = 1Gbps, if 64B pkt size"):default(0.000000672):convert(tonumber)
	parser:option("-b --probe2", "Probe from dev2 every b seconds, default = 1Gbps, if 64B pkt size"):default(0.000000672):convert(tonumber)
	parser:option("-f --file1", "Filename for latency histogram dev1."):default("/tmp/software-all-1.csv")
	parser:option("-g --file2", "Filename for latency histogram dev2."):default("/tmp/software-all-2.csv")
    parser:option("-w --warmup", "Warmup samples"):default(1000000):convert(tonumber)
end

function master(args)
	local dev1 = device.config{port = args.dev1, rxQueues = 1, txQueues = 1}
	local dev2 = device.config{port = args.dev2, rxQueues = 1, txQueues = 1}
	device.waitForLinks()
    print(args.file1)
    print(args.file2)
    collectgarbage('stop')
	mg.startTask("txTimestamper", dev1:getTxQueue(0), args.probe1)
	mg.startTask("rxTimestamper", dev2:getRxQueue(0), args.file1, args.warmup)
	mg.startTask("txTimestamper", dev2:getTxQueue(0), args.probe2)
	mg.startTask("rxTimestamper", dev1:getRxQueue(0), args.file2, args.warmup)

	mg.waitForTasks()
end

function loadSlave(queue)
    --collectgarbage('stop')
    jit.off()
	local mem = memory.createMemPool(function(buf)
		buf:getEthernetPacket():fill{
			ethSrc = queue,
			ethDst = ETH_DST,
			ethType = 0x1234
		}
	end)
	local bufs = mem:bufArray()
	while mg.running() do
		bufs:alloc(PKT_SIZE)
		queue:send(bufs)
	end
end

function txTimestamper(queue, probesec)
    --collectgarbage('stop')
    jit.off()
	local mem = memory.createMemPool(function(buf)
		-- just to use the default filter here
		-- you can use whatever packet type you want
		buf:getPtpPacket():fill{
			ethSrc = queue,
			ethDst = ETH_DST
		}
	end)
	mg.sleepMillis(1000) -- ensure that the load task is running
	local bufs = mem:bufArray(1)
	local rateLimit = timer:new(probesec) -- 10kpps timestamped packets
	local i = 0
	while mg.running() do
		bufs:alloc(PKT_SIZE)
		queue:sendWithTimestamp(bufs)
		rateLimit:wait()
		rateLimit:reset()
		i = i + 1
	end
	mg.sleepMillis(500)
	mg.stop()
end

function rxTimestamper(queue, file, warmup_iter)
    --collectgarbage('stop')
    jit.off()
	local tscFreq = mg.getCyclesFrequency()
	local bufs = memory.bufArray(64)
	local results = {}
	local rxts = {}
    local curr_iter = 0
	while mg.running() do
		local numPkts = queue:recvWithTimestamps(bufs)
        if curr_iter > warmup_iter then
		    for i = 1, numPkts do
			    local rxTs = bufs[i].udata64
			    local txTs = bufs[i]:getSoftwareTxTimestamp()
			    results[#results + 1] = tonumber(rxTs - txTs) / tscFreq * 10^9 -- to nanoseconds
			    rxts[#rxts + 1] = tonumber(rxTs)
		    end
        end
        curr_iter = curr_iter + 1
        bufs:free(numPkts)
	end
    print(file)
	local f = io.open(file, "w+")
	for i, v in ipairs(results) do
		f:write(v .. "\n")
	end
	f:close()
end
