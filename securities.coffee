### 智能化的投資品種,
  根據行情結構,應對最新行情作出相應操作
  將逐步演化完善
  以下代碼等名目,僅僅是用於對接現有的Python接口,將來系統中都可以統一換成中文
###
util = require 'util'

class Security
  constructor: (keeper, @代碼, @名稱, @策略, @百分比=0.618)->
    ### 經過如下處理,@對策 function中的this即此證券
    ###
    @就緒 = false
    @對策 = @策略.對策

  # 僅在`生成載入`中使用
  初始: (keeper, 回執) =>
    @策略.注入 keeper, this, (err,done)=>
      unless err?
        @就緒 = done
        #util.log "securities.coffee >> 生成", @代碼
        回執(err, done)

  應對: (最新, 回執)->
    @對策(最新, 回執)

  clearIntervals: ->
    for each in @intervals #[@iMin, @iDay, @iWeek]
      clearInterval(each)

  toString: -> "a Security 代碼: #{@代碼}"

  為分級A基金: ->
    /^(1|5)/.test(@代碼[0]) and /A|稳|先/.test(@名稱)

  求買入比重: ->
    if @為分級A基金()
      0.00382
    else
      0.00191

  求止損比重: ->
    if @為分級A基金()
      0.618
    else
      0.832

  求賣出比重: ->
    if @為分級A基金()
      0.382
    else
      0.618

# ==========================================================================



### 目標證券群
  此處控制系統中同一個策略每一品種僅需一個object

  根據外部所提供行情,以及預定策略,實時決策操作
###
###
  @symbols: ['135333','xxdge']

  @symbols 就不要改成中文了,各處用到,改動麻煩,且代碼中文詞很容易碰到,造成混淆
###
class Securities
  constructor:(@symbols, @策略)->
    @各券商接口 = []
    @position = [] #null

    @清潔 = false
    @品種={}

  ###* 若@清潔 則選擇可觀察或持倉品種,忽略其他
    回執無用,是否去掉?要搜索下哪些地方用到 此法
  *###
  生成載入: (代碼,名稱, 回執)->
    ###* 先生成,不需要再刪除
    *###
    證券 = new Security(this, 代碼, 名稱, @策略)
    @品種[代碼] = 證券

    # 僅在`生成載入`中使用
    初始 = (回執)->
      證券.策略.注入 this, 證券, (err,done)->
        unless err?
          證券.就緒 = done
          #util.log "securities.coffee >> 生成", @代碼
          回執(err, done)

    #證券.初始 this, (err,done)=>
    #初始 (err,done)=>
    
    組合管家 = this
    證券.策略.注入 this, 證券, (err,done)->
      ###* 初始設置需要一些時間,tick有可能已經過時了,故沒有操作指令
        在其他地方使用本法時,不必回執
      *###
      if 回執?
        回執(null)

      unless err?
        證券.就緒 = done
        if done
          if 組合管家.清潔
            ###* 過濾層一. 可觀察的超跌低位品種不管他,留下來
            *###
            unless 證券.可觀察
              ### 若等就緒不少會漏網;如果網絡好,不等就緒也沒問題;若不好也最多多生成清理幾次
              if 證券.就緒
                @忽略(代碼)
              ###
              @忽略(代碼)


  ### 從券商賬戶讀取的持倉品種,必須繼續跟蹤,以便止盈止損
  ###
  持倉品種:(symbols)->
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
          # 先將之加入,發現不需要再去掉(須檢測 symbol 是否正常?)
          @symbols.push symbol

  忽略: (symbol)->
    ###*
      過濾層一. 可觀察的超跌低位品種不管他,留下來
      過濾層二. 持倉的品種,即使非可觀察低位品種,也必須留下來,作止盈止損監控
      其他的,當天都不必跟蹤了
    *###
    unless symbol in @position
      @品種[symbol].clearIntervals()
      delete @品種[symbol]
      @symbols.splice(@symbols.indexOf(symbol),1)
      #console.log "securities >> #{@symbols.length}: #{@symbols}"
      util.log "securities >> #{@symbols.length}"

  # jso: 由一組即時行情構成
  應對組合即時行情: (jso, 回執)->
    for code, tick of jso
      symbol = tick.代碼
      # 正常情況:
      if symbol in @symbols
        unless @品種[symbol]?
          @生成載入(tick.代碼, tick.名稱, 回執)
        else
          if @品種[symbol].就緒
            @品種[symbol].應對(tick, 回執)
          else
            回執 null

      else
        # 異常情況,理論上不應出現,但可能是因為網絡關係,時有出現
        # 這是臨時限制,由於之前secode在沒symbols時,會出現'sz','szsz',已改,暫且保留
        if symbol isnt 'sz'
          @symbols.push symbol
          @生成載入(tick.代碼, tick.名稱, 回執)
          util.log 'securities.coffee>> 應對 新出現 tick.代碼:',symbol #,@品種[symbol]

  clearIntervals: ->
    util.log 'securities>> clearIntervals'
    for each in @symbols
      @品種[each].clearIntervals()

module.exports = Securities
