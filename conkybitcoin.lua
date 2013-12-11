--Configuration. Edit as needed.
local bitcoin = {
	rpc = {
		username = "some_name", --the RPC username set in your bitcoin.conf
		password = "some_password", --and the password
		host = "localhost", --the host to connect to
		port = 8332, --the port for RPC connections
	},
	format = {
		plus  = '${color3} ', --prefix for positive numbers
		zero  = '${color2} ', --prefix for zero
		minus = '${color2}',  --prefix for negative numbers
		date  = '%a %y/%m/%d %H:%M:%S', --format for dates (look up strftime)
	},
	mtgox = {
		update_interval = 5 * 60, --how often to update, in seconds
			--don't set too low to avoid stressing (and being ratelimited from)
			--the MtGox servers.
	},
}
--End of configuration.


local json = require('json') --http://json.luaforge.net/
local rpc  = require('json.rpc')
local http = require('socket.http') --http://luaforge.net/projects/luasocket/
local ssl = require('ssl') --https://github.com/LuaDist/luasec
--[[ these should all be installable with LuaRocks:
sudo luarocks install json4lua
sudo luarocks install luasocket
sudo luarocks install luasec
however, I had to do:
sudo luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu/ ]]

unpack = unpack or table.unpack --Lua 5.1 and 5.2 compat


--Set up other fields
bitcoin.rpc.url = --Build the RPC URL from the config.
	('http://<username>:<password>@<host>:<port>'):gsub('<(.-)>', bitcoin.rpc)
bitcoin.mtgox.currency = {}


--Pack args into an array.
--Returns a table containing the args and an 'n' field giving
--the number of args.
local function tpack(...)
	return {n=select('#', ...), ...}
end


--Return all items up to the first nil in an array.
local function tunpack(tbl)
	local i = 1
	while tbl[i] do i = i + 1 end --find first nil
	return unpack(tbl, 1, i-1) --return everything before it
end


--Remove an item from an array and decrement its n field.
local function tremove(tbl, idx)
	if tbl.n and tbl.n > 0 then tbl.n = tbl.n - 1 end
	return table.remove(tbl, idx)
end


--"create" method for https sockets. wraps them in a proxy object,
--which takes care of SSL handshakes.
local function create_https()
	local params = {
		mode     = 'client',
		protocol = 'sslv23',
		cafile   = '/etc/ssl/certs/ca-certificates.crt',
		verify   = 'peer',
		options  = 'all',
	}

	local try = socket.try
	local sock = { base = try(socket.tcp()) }

	local function idx(self, key) --proxy's __index method.
		--we have to give functions the actual socket object,
		--not this proxy table.
		local val = rawget(self, 'base')[key]
		if type(val) ~= 'function' then return val end
		return function(proxy, ...)
			local base = proxy.base
			return base[key](base,...)
		end
	end

	function sock:connect(host, port)
		socket.try(self.base:connect(host, port))
		self.base = socket.try(ssl.wrap(self.base, params))
		socket.try(self.base:dohandshake())
		return 1
	end

	return setmetatable(sock, {__index = idx})
end


--For each date field in a table, replaces it with a formatted date string and
--adds a "_raw" version with the Unix timestamp.
local function handle_dates(tbl, fields)
	for i, field in ipairs(fields) do
		local date = tbl[field]
		tbl[field .. '_raw'] = tbl[field]
		tbl[field] = os.date(bitcoin.format.date, date)
	end
	return tbl
end


--For each amount field in a table, replaces it with one prefixed with the
--strings from config, and adds a "_raw" version with the original.
local function handle_amounts(tbl, fields)
	for i, field in ipairs(fields) do
		local val = tonumber(tbl[field]) or 0
		tbl[field .. '_raw'] = tbl[field]

		local str = bitcoin.format.zero
		if     val > 0 then str = bitcoin.format.plus
		elseif val < 0 then str = bitcoin.format.minus
		end
		tbl[field] = str .. val
	end
end


--Read the account name from the args, which can be in quotes if it contains
--spaces. Removes the fields from the args table, and returns the account
--name.
local function get_account_name(args)
	--if no name provided, use the default account.
	if not args[1] then return nil end

	--read the first arg. if it begins with a quote, keep reading until we
	--find the end quote.
	local account_name = tremove(args, 1) or ''
	if account_name:sub(1,1) == '"' then
		while args[1] and account_name:sub(-1) ~= '"' do
			account_name = account_name .. ' ' .. tremove(args, 1)
		end
		account_name = account_name:sub(2, -2) --strip quotes
	end

	return account_name
end


--Perform an RPC call.
function bitcoin:rpc_call(method, ...)
	--print("rpc_call ", method, ...)
	return rpc.call(self.rpc.url, method, ...)
end


--Looks up a transaction for an account.
--account: the account to look up.
--idx: which transaction to look up. 1 = most recent, 2 = second most recent...
function bitcoin:gettransactions(account, idx)
	local tx, err = self:rpc_call('listtransactions', account, 1, idx-1)
	if not tx then return nil, err end
	tx = tx[1] --get first (only) item from returned array

	handle_amounts(tx, {'amount', 'fee'})
	handle_dates(tx, {'blocktime', 'time', 'timereceived'})
	return tx
end


--For methods that don't require different numbers of args,
--we can use metatable magic.
--We need tunpack here to avoid passing nils to rpc.call,
--because it doesn't treat those the same as missing arguments.
local meta = {}
function meta:__index(name)
	return function(self, ...)
		local t = {...}
		return self:rpc_call(name, tunpack(t))
	end
end
setmetatable(bitcoin, meta)


--Looks up the balance of the specified account.
function conky_bitcoin_balance(...)
	local args = tpack(...)
	local account_name = get_account_name(args)

	local balance, err = bitcoin:getbalance(account_name)
	if balance then
		balance = assert(tonumber(balance))
		local key = 'zero'
		if     balance > 0 then key = 'plus'
		elseif balance < 0 then key = 'minus'
		end

		return bitcoin.format[key] .. balance
	else return tostring(err)
	end
end


--Retrieves various info from bitcoind.
function conky_bitcoin_info(...)
	local args = tpack(...)
	local fmt = table.concat(args, ' ', 1, args.n)
	local data, err = bitcoin:getinfo()
	if not data then return tostring(err) end

	handle_dates(data, {'keypoololdest'})
	return fmt:gsub('<(.-)>', data)
end


--Retrieves info on a transaction.
function conky_bitcoin_transaction(idx, ...)
	local args = tpack(...)
	local account_name = get_account_name(args)
	local fmt = table.concat(args, ' ', 1, args.n)

	--get the transaction info.
	local data, err = bitcoin:gettransactions(account_name, idx)
	if not data then return tostring(err) end

	return fmt:gsub('<(.-)>', data)
end


--Looks up MtGox ticket data.
function conky_mtgox(curname, ...)
	local args = tpack(...)
	local fmt = table.concat(args, ' ', 1, args.n)
	local now = os.time()

	bitcoin.mtgox.currency[curname] = bitcoin.mtgox.currency[curname] or {}
	local currency = bitcoin.mtgox.currency[curname]
	local url = 'https://data.mtgox.com:443/api/2/BTC' ..
		curname .. '/money/ticker'

	currency.last_update = currency.last_update or 0
	if now - currency.last_update >= bitcoin.mtgox.update_interval then
		currency.last_update = now --even if request fails

		local response_body = {}
		local ok, status, headers, statusline = http.request {
			url = url,
			create = create_https,
			sink = ltn12.sink.table(response_body), --required with this method
		}
		local text = table.concat(response_body)

		if (not ok) or (not status) or (not tonumber(status))
		or (tonumber(status) >= 300) then
			return "HTTP " .. tostring(status)
		end

		local ok, data = pcall(json.decode, text)
		if ok and type(data) == 'table' then
			for k, v in pairs(data.data) do currency[k] = v end
		else return tostring(data)
		end
	end

	return fmt:gsub('<(.-)>', function(key)
		return currency[key] and currency[key].value
	end)
end
