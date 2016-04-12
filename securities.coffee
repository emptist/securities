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
    @指令集 = null # 組合/證券/池等法均可持有 指令集

  應對: (最新, 回執)->
    @對策(最新, 回執)

  ###

   ------------------ 策略管理:審核實施與失效清理  ------------------------

    逐利或稱之為豐收策略(春生夏長),依據是行情結構,故因池而異,借宿於池.

    應運而生,失效清除:
      1. 當策略初生時,存入池(基於池的)或證券中,每一輪新即時行情到來,都分別以各項策略掃描,各自運行
      2. 當執行次數超過限制次數時,以及其他條件滿足時,則清理掉該策略,不再掃描.

    將來還需增加更高層次的審核,如:
      1. 不同週期的池,日線池,週線池,若各有策略埋伏,則在證券層次加以權衡取捨.
      2. 而不同證券風險和效率不同,在組合層次加以取捨.
      3. 不同組合在賬戶中加以管理.如此則全面.


  操作價次審核: (指令, 回執)->
    #{指令類型, 策略} = 指令
    {指令類型,策略,價位} = 指令

    unless @[指令類型]? then @[指令類型] = {}

    unless @[指令類型]?[策略]?
      認可 = true
    else
      記錄 = @[指令類型][策略]
      認可 = 指令.後續價次審核(記錄.價位, 記錄.次數)

    # 認可後再記錄,否則數量虛增,再有有效指令就不好判斷. 如需記錄所有指令,可另開變量
    if 認可
      指令.次數 = 1 + (@[指令類型][策略]?.次數 ? 0)
      if 指令.期滿 # 這個還沒寫
        delete @[指令類型][策略]
      else
        @[指令類型][策略] =
          價位: 價位
          次數: 指令.次數

      回執(指令)
  ###


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

    組合管家 = this
    證券.策略.注入初始數據 組合管家, 證券, (err,done)->
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
              組合管家.忽略(代碼)


  ### 從券商賬戶讀取的持倉品種,必須繼續跟蹤,以便止盈止損
  ###
  持倉品種:(symbols)->
    # 有時是空倉的,所以@position可以為空且須先設置
    if symbols?
      for symbol in symbols
        unless symbol in @position
          @position.push symbol
    @更新證券表(symbols)

  更新證券表:(symbols)->
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
