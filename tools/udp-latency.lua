local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local log    = require "log"

-- set addresses here
local MAC1		= "68:05:CA:37:E0:A9"
local MAC2      = "68:05:ca:37:de:79"
local IP1	= "10.0.0.10"
local IP2		= "10.1.0.10"
local SRC_PORT		= 1234
local DST_PORT		= 319

function configure(parser)
	parser:description("Generates UDP traffic and measure latencies. Edit the source to modify constants like IPs.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
	parser:option("-r --rate", "Load rate (in one direction) in Mbit/s."):default(1000):convert(tonumber)
	parser:option("-f --file", "Filename of the latency histogram."):default("histogram.csv")
	parser:option("-s --size", "Load-packet size."):default(60):convert(tonumber)
    parser:option("-w --warmup", "Warmup samples."):default(10000):convert(tonumber)
    parser:option("-t --total", "Total samples."):default(1000000):convert(tonumber)
end

function master(args)
	dev1 = device.config{port = args.txDev, rxQueues = 2, txQueues = 2}
	dev2 = device.config{port = args.rxDev, rxQueues = 2, txQueues = 2}
	device.waitForLinks()
    dev1:getTxQueue(0):setRate(args.rate)
    dev2:getTxQueue(0):setRate(args.rate)

	mg.startTask("loadSlave", dev1:getTxQueue(0), args.size, parseIPAddress(IP1), parseIPAddress(IP2))
    mg.startTask("loadSlave", dev2:getTxQueue(0), args.size, parseIPAddress(IP2), parseIPAddress(IP1))
	mg.startTask("timerSlave", dev1:getTxQueue(1), dev2:getRxQueue(1), args.size, args.warmup, args.total, args.file)
	mg.waitForTasks()
end

local function fillUdpPacket(buf, len)
	buf:getUdpPacket():fill{
		ethSrc = queue,
		ethDst = DST_MAC,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end

function loadSlave(queue, size, src_ip, dst_ip)
	local mempool = memory.createMemPool(function(buf)
		fillUdpPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local counter = 0
	while mg.running() do
		bufs:alloc(size)
		for i, buf in ipairs(bufs) do
			local pkt = buf:getUdpPacket()
			pkt.ip4.src:set(src_ip)
            pkt.ip4.dst:set(dst_ip)
			counter = counter + 1
		end
		-- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		bufs:offloadUdpChecksums()
		queue:send(bufs)
	end
    print("Total load pkts:")
    print(counter)
end

function timerSlave(txQueue, rxQueue, size, warmup, total, file)
	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(1000) -- ensure that the load task is running
    local counter = 0
    ipsrc = parseIPAddress(IP1)
	while counter < warmup + total do
        rtt = timestamper:measureLatency(size, function(buf)
		    fillUdpPacket(buf, size)
			local pkt = buf:getUdpPacket()
			pkt.ip4.src:set(ipsrc)
		    end)
        if counter > warmup then
		    hist:update(rtt)
        end
        counter = counter + 1
	end
	mg.sleepMillis(300)
    print("Counter:")
    print(counter)
	hist:print()
	hist:save(file)
end

