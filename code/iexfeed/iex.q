\d .iex

main_url:@[value;`main_url;"https://api.iextrading.com"];
convert_epoch:@[value;`convert_epoch;{"p"$1970.01.01D+1000000j*x}];
reqtype:@[value;`reqtype;`both];
syms:@[value;`syms;`CAT`DOG];
callback:@[value;`callback;".u.upd"];
callbackhandle:@[value;`callbackhandle;0i];
quote_suffix:@[value;`quote_suffix;{[sym] "/1.0/stock/",sym,"/quote"}];
trade_suffix:@[value;`trade_suffix;{[sym]"/1.0/tops/last?symbols=",sym}];
upd:@[value;`upd;{[t;x] .iex.callbackhandle(.iex.callback;t; value flip x)}];
timerperiod:@[value;`timerperiod;0D00:00:02.000];

.iex.init:{[x]
   if[`main_url in key[x];.iex.main_url:x[`main_url]];
   if[`quote_suffix in key[x];.iex.quote_suffix:x[`quote_suffix]];
   if[`trade_suffix in key[x];.iex.trade_suffix:x[`trade_suffix]];
   if[`syms in key[x];.iex.syms: upper x[`syms]];
   if[`reqtype in key[x];.iex.reqtype:x[`reqtype]];
   if[`callbackconnection in key[x];.iex.callbackhandle :neg[hopen[.iex.callbackconnection:x[`callbackconnection]]]];
   if[`callbackhandle in key[x];.iex.callbackhandle:x[`callbackhandle]];
   if[`callback in key[x];.iex.callback: $[.iex.callbackhandle=0; string @[value;x[`callback];{[x;y]x set {[t;x]x}}[x[`callback]]]; x[`callback]]];
   if[`upd in key[x]; .iex.upd:x[`upd]];
   .iex.timer:$[not .iex.reqtype in key .iex.timer_dict;'`timer;.iex.timer_dict[.iex.reqtype]];
   }

quote_suffix:{[sym]  
   "/1.0/stock/",sym,"/quote" 
   }

trade_suffix:{[sym]
   "/1.0/tops/last?symbols=",sym
   }

get_data:{[main_url;suffix]
   .Q.hg `$main_url,suffix
   }

get_last_trade:{tab:{[syms]
   / This function can run for multiple securities.
   syms:$[1<count syms;"," sv string[upper syms];string[upper syms]];
   / Construct the GET request
   suffix:.iex.trade_suffix[syms];
   / Parse json response and put into table. Trade data from https://iextrading.com/developer/
   data:.j.k .iex.get_data[.iex.main_url;suffix];
   tab:select time:"P"$string(.iex.convert_epoch time) ,sym:`$symbol, price:`float$price, size:`int$size, stop:(count data)#0b, cond:(count data)#`char$(), ex:(count data)#`char$() from data
   }[.iex.syms]; .iex.upd[`trade;tab]
   }


get_quote:{tab:raze {[sym]
   sym:string[upper sym];
   suffix:.iex.quote_suffix[sym];
   / Parse json response and put into table
   data: enlist .j.k .iex.get_data[.iex.main_url;suffix];
   select time:"P"$string(.iex.convert_epoch latestUpdate), sym:`$symbol, bid: `float$iexBidPrice, ask:`float$iexAskPrice, bsize:`long$iexBidSize, asize:`long$iexAskSize, mode:(count data)#`char$(), ex:(count data)#`char$() from data
   }'[.iex.syms,()]; .iex.upd[`quote;tab] 
   }


timer_tradeonly:.iex.get_last_trade
timer_quoteonly:.iex.get_quote
timer_both:{.iex.get_last_trade[];.iex.get_quote[]}
timer_dict:`trade`quote`both!(timer_tradeonly;timer_quoteonly;timer_both)
timer:$[not .iex.reqtype in key .iex.timer_dict;'`timer;.iex.timer_dict[.iex.reqtype]]

\d . 
