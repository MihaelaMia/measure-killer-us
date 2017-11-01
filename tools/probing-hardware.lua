	--- 2-way 2 port L2 fwd
local mg		= require "moongen" 
local memory	= require "memory"
local device	= require "device"
local ts		= require "timestamping"
local filter	= require "filter"
local stats		= require "stats"
local hist		= require "histogram"
local timer		= require "timer"
local log		= require "log"

local PKT_SIZE	= 60 -- without CRC
local ETH_DST = "10:11:12:13:14:15"

function configure(parser)
    print("configure parser")
	parser:description("Probing - hardware timestamps")
	parser:argument("dev1", "Device to transmit/receive from."):convert(tonumber)
	parser:argument("dev2", "Device to transmit/receive from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(5000):convert(tonumber)
	parser:option("-f --file", "Filename of the latency histogram."):default("histogram.csv")
    parser:option("-w --warmup","How many samples are discarded from the beginning"):default(1000):convert(tonumber)
end

function master(args)
    print("master")
	local dev1 = device.config({port = args.dev1, rxQueues = 2, txQueues = 2})
	local dev2 = device.config({port = args.dev2, rxQueues = 2, txQueues = 2})
	device.waitForLinks()
	dev1:getTxQueue(0):setRate(args.rate)
	dev2:getTxQueue(0):setRate(args.rate)
	mg.startTask("loadSlave", dev1:getTxQueue(0))
	mg.startTask("loadSlave", dev2:getTxQueue(0))
	mg.startSharedTask("timerSlave", dev1:getTxQueue(1), dev2:getRxQueue(1), args.file, args.warmup)
	mg.waitForTasks()
end

function loadSlave(queue)
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

function timerSlave(txQueue, rxQueue, histfile, warmup_iter)
	local timestamper = ts:newTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(1000) -- ensure that the load task is running
    local curr_iter = 0
    local sec_start = os.time()
    print(os.time())
	while mg.running() do
        rtt = timestamper:measureLatency(function(buf) buf:getEthernetPacket().eth.dst:setString(ETH_DST) end)
        if curr_iter > warmup_iter then
		    hist:update(rtt)
        end
        curr_iter = curr_iter + 1
	end
    local total_sec = os.time() - sec_start
    print(total_sec)
    print("Curr iter " .. curr_iter)
    print("Hardware timestamp rate final = " .. curr_iter/total_sec)
	hist:print()
    print("File " .. histfile)
	hist:save(histfile)
end

