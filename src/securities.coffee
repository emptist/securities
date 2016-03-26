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


  初始: (master, 回執) =>
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
    #util.log '首批代碼表:', @symbols
    #@策略.準備()
    @品種={}
    for symbol in @symbols
      @生成載入(symbol)

  ###* 若@清潔 則選擇可觀察或持倉品種,忽略其他
  *###
  生成載入: (symbol)->
    證券 = new Security(this, symbol, @策略)
    ###* 先生成,不需要再刪除
    *###
    @品種[symbol] = 證券
    證券.初始 this, (err,done)=>
      unless err?
        if done
          if @清潔
            ###* 過濾層一. 可觀察的超跌低位品種不管他,留下來
            *###
            unless 證券.可觀察
              @忽略(symbol)


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

            先加入,發現不需要再去掉
          ###
          @symbols.push symbol
          @生成載入(symbol)



  ### 已無用,暫時保留,測試有無bug
  稍後可刪除
  ###
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



  忽略: (symbol)->
    ###* 過濾層一. 可觀察的超跌低位品種不管他,留下來
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
    for code, tick of jso
      symbol = tick.代碼
      unless symbol in @symbols
        util.log 'securities.coffee>> 應對 新出現 tick.代碼:',symbol
        # 這是臨時限制,由於之前secode在沒symbols時,會出現'sz','szsz',已改,暫且保留
        if symbol isnt 'sz'
          @symbols.push symbol
          @生成載入(symbol) # 取代了下一行代碼,若有錯,再改回
          #@品種[symbol] = new Security(this, symbol,@策略)

      # 這是臨時限制,由於之前secode在沒symbols時,會出現'sz','szsz',已改,暫且保留
      if symbol isnt 'sz'
        @品種[symbol].應對(tick, 回執)

      #@濾過(symbol)


  clearIntervals: ->
    util.log 'securities>> clearIntervals'
    for each in @symbols
      @品種[each].clearIntervals()

module.exports = Securities
