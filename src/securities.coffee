### 智能化的投資品種,
  根據行情結構,應對最新行情作出相應操作
  將逐步演化完善
  以下代碼等名目,僅僅是用於對接現有的Python接口,將來系統中都可以統一換成中文
###
util = require 'util'

class Security
  constructor: (master, 代碼, 策略, @百分比=0.618)->
    ### 經過如下處理,@對策 function中的this即此證券品種
    ###
    @策略 = 策略
    @對策 = @策略.對策
    @代碼 = 代碼
    @就緒 = false

    ###
    @策略.定制 master, this, (err,done)=>
      unless err?
        @就緒 = true
        #util.log "securities.coffee >> 生成", @代碼
    ###

  init: (master, 回執) =>
    @策略.定制 master, this, (err,done)=>
      unless err?
        @就緒 = true
        #util.log "securities.coffee >> 生成", @代碼
        回執(err, done)

  應對: (最新, 回執)->
    @對策(最新, 回執)

  clearIntervals: ->
    for each in @intervals #[@iMin, @iDay, @iWeek]
      clearInterval(each)

  toString: -> "a Security 代碼: #{@代碼}" # "證券品種代碼#{@代碼}"


### 目標證券群
  此處控制系統中同一個策略每一品種僅需一個object

  根據外部所提供行情,以及預定策略,實時決策操作
###
###
  @symbols: ['135333','xxdge']
###
class Securities
  constructor:(@symbols, @策略)->
    @清潔 = false
    @position = null
    #util.log '初始代碼表:', @symbols
    #@策略.準備()
    @品種={}
    for symbol in @symbols
      @生成載入(symbol)

  生成載入: (symbol)->
    證券 = new Security(this, symbol, @策略)
    @品種[symbol] = 證券
    證券.init this, (err,done)=>
      unless err?
        if done
          # 在這裡做清理?
          console.log 證券
          @濾過(symbol)


  ### 從券商賬戶讀取的持倉品種,必須繼續跟蹤,以便止盈止損
  ###
  持倉品種:(symbols)->
    ### @position存在,
      表明已經匯集了持倉品種,可以執行後續分析
    ###
    unless @position?
      @position = []
    # 有時是空倉的,所以@position可以為空且須先設置
    if symbols?
      for symbol in symbols
        unless symbol in @position
          @position.push symbol
    @更新品種(symbols)

  更新品種:(symbols)->
    if symbols?
      for symbol in symbols
        unless symbol in @symbols
          ### 須檢測 symbol 是否正常?
          #if symbol.length is 6
          ###
          @symbols.push symbol
          @生成載入(symbol)

  濾過: (symbol)->
    if @清潔
      if @品種[symbol]?.就緒
        ###* 過濾層一. 可觀察的超跌低位品種不管他,留下來
        *###
        unless @品種[symbol].可觀察
          ###* 若有此變量,則表明已經匯集好持倉品種,可以執行以下操作
          *###
          if @position?
            ###* 過濾層二. 持倉的品種,即使非可觀察低位品種,也必須留下來,作止盈止損監控
              其他的,當天都不必跟蹤了
            *###
            unless symbol in @position
              @品種[symbol].clearIntervals()
              delete @品種[symbol]
              @symbols.splice(@symbols.indexOf(symbol),1)
              util.log "securities >> 監控範圍#{@symbols.length}個品種: #{@symbols}"

  # jso: 由一組即時行情構成
  應對: (jso, 回執)->
    # code 格式: sh600000,sz159915, 此處未用
    # 不知為何出現一個代碼為sz的東西,未知bug出現在哪個環節
    for code, tick of jso
      symbol = tick.代碼
      # 剔除不需要繼續跟蹤的品種
      # 可能放在此處破壞了某種機制,不行!不要再嘗試了
      unless symbol in @symbols
        util.log 'securities.coffee>> 應對 新出現 tick.代碼:',symbol
        # 這是臨時使用的限制,由於發現在沒有獲得symbols時,會出現'sz','szsz'這些代碼
        if symbol isnt 'sz'
          @symbols.push symbol
          @品種[symbol] = new Security(this, symbol,@策略)
      # 這是臨時使用的限制,由於發現在沒有獲得symbols時,會出現'sz','szsz'這些代碼
      if symbol isnt 'sz'
        @品種[symbol].應對(tick, 回執)

      #@濾過(symbol)


  clearIntervals: ->
    util.log 'securities>> clearIntervals'
    for each in @symbols
      @品種[each].clearIntervals()

module.exports = Securities
