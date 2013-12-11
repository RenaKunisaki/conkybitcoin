Script to display [Bitcoin](http://bitcoin.org) and [MtGox](https://www.mtgox.com) info in [Conky](http://conky.sourceforge.net).

This script requires [Lua 5.1](http://www.lua.org/), [JSON4Lua](http://json.luaforge.net), [LuaSocket](http://luaforge.net/projects/luasocket), and [LuaSec](https://github.com/LuaDist/luasec).
These can be installed using [LuaRocks](http://luarocks.org/).

To use this script, add a line to `~/.conkyrc` to load it:

    lua_load .scripts/conkybitcoin.lua

You'll probably also want to define some colours while you're there:

    color2 FF0000
    color3 00FF00

(if you're already using color2 and color3, you can specify other colours by
editing the config table at the beginning of the script.)

Next, edit your `~/.bitcoin/bitcoin.conf` to enable [RPC](https://en.bitcoin.it/wiki/API_reference_%28JSON-RPC%29) by adding these lines:

    server=1
    rpcuser=some_name
    rpcpassword=some_password
    rpcport=8332

(make sure to restart bitcoind after editing.)

Finally, edit the config table at the beginning of the script as needed.

This script adds the following variables that you can use in the text section
of `~/.conkyrc`:

* `bitcoin_balance`: The balance of an account or all accounts.
* `bitcoin_info`: Various info about bitcoind.
* `bitcoin_transaction`: Info about a transaction involving your account.
* `mtgox`: Info from [MtGox](https://www.mtgox.com) ticker.

`bitcoin_balance` and `bitcoin_transaction` can accept an account name. This must be
in quotes if it contains spaces. The account name `*` means all accounts.
An empty account name, i.e. account name `""`, is the default account, as
documented at: `https://en.bitcoin.it/wiki/Accounts_explained`.

Each of these variables can be used with any of Conky's `lua`, `lua_parse`, `lua_bar`,
`lua_gauge` and `lua_graph` functions, but you may need to change the prefixes in
the config table to remove the color prefixes first.

Examples
--------
(`$color` is used to reset to the default color.)

    Balance of all accounts: ${lua_parse bitcoin_balance}$color
    Balance of default account: ${lua_parse bitcoin_balance *}$color
    Balance of some other account: ${lua_parse bitcoin_balance "My Account"}$color
    ${lua_parse bitcoin_info Client version: <version>; have <blocks> blocks}

    Recent transactions of Reddit Tips account:
    ${lua_parse bitcoin_transaction 1 "Reddit Tips" <time> <amount>}$color
    ${lua_parse bitcoin_transaction 2 "Reddit Tips" <time> <amount>}$color
    ${lua_parse bitcoin_transaction 3 "Reddit Tips" <time> <amount>}$color

    CAD: ${lua_parse mtgox CAD <avg> <buy> <sell>}$color
    USD: ${lua_parse mtgox USD <avg> <buy> <sell>}$color


Functions
---------

**bitcoin_balance**: `${lua_parse bitcoin_balance account}`

Displays the balance of an account.
If `account` is omitted, it will show the balance of all accounts.

----------

**bitcoin_info**: `${lua_parse bitcoin_info format_string}`

Displays various info about bitcoind (everything from the `getinfo`
RPC command).

`format_string` is the text to display. Anything in <brackets> is a variable to
replace. The available variables are:

* `balance`: Total balance of all accounts.
* `blocks`: Number of blocks downloaded.
* `connections`: Number of peers connected.
* `difficulty`: The difficulty of mining a block.
* `errors`: List of any errors that have occurred.
* `keypoololdest`: Date of oldest item in the key pool.
* `keypoololdest_raw`: Unix timestamp of oldest item in the key pool.
* `keypoolsize`: Size of the key pool.
* `paytxfee`: Transaction fee your client is configured to pay.
* `protocolversion`: What version of the protocol your client uses.
* `proxy`: The address of your proxy server, if any.
* `testnet`: true or false, whether you're using the test network.
* `timeoffset`: No idea.
* `version`: Your client's version.
* `walletversion`: Your wallet's format version.

----------

**bitcoin_transaction**: `${lua_parse bitcoin_transaction idx account format_string}`

Displays the details of a recent transaction.

`idx` is which transaction to show: 1 = the most recent, 2 = second most recent...

`account` is the account name to show. Again this can be `*` for all accounts.

`format_string` is the text to display, as in `bitcoin_info`. Variables are:

* `account`: The name of the account.
* `address`: Your address used for this transaction.
* `amount`: The amount transferred (positive for received, negative for sent).
* `amount_str`: The amount, with prefixes as defined in config.
* `blockhash`: The hash of the block.
* `blockindex`: The index in the block.
* `blocktime`: When the block was generated.
* `category`: "send" or "receive".
* `confirmations`: Number of times this transaction has been confirmed.
* `fee`: The fee paid for this transaction. (Always negative or zero.)
* `time`: The date that this transaction was generated.
* `time_raw`: The Unix timestamp that this transaction was generated.
* `timereceived`: The date that this transaction was received by you.
* `timereceived_raw`: The Unix timestamp that this transaction was received by you.
* `txid`: The transaction ID.

----------

**mtgox**: `${lua_parse mtgox currency format_string}`

Displays ticker data from [MtGox](https://www.mtgox.com).

`currency` is the currency to look up, e.g. USD, CAD, JPY.

`format_string` is the text to display, as in `bitcoin_info`.

Variables are:
  avg, buy, high, last, last\_all, last\_local, last\_orig, low, sell, vol, vwap

----------

Send tips to `1Rena68BBCMSyyCzbULaKP6qZfV68hsLq`.
