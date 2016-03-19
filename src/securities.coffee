### 智能化的投資品種,
  根據行情結構,應對最新行情作出相應操作
  將逐步演化完善
  以下代碼等名目,僅僅是用於對接現有的Python接口,將來系統中都可以統一換成中文
###


class Security
  constructor: (master, 代碼, 策略, @百分比=0.618)->
    ### 經過如下處理,@對策 function中的this即此證券品種
    ###
    @策略 = 策略
    @對策 = @策略.對策
    @代碼 = 代碼

    @策略.定制 master, this, (err,done)=>
      unless err?
        console.log "生成", @代碼

  clearIntervals: ->
    for each in [@iM05, @iDay, @iWeek]
      clearInterval(each)

  toString: -> "a Security 代碼: #{@代碼}" # "證券品種代碼#{@代碼}"
  ###合適: (回應)->
    @代碼? and 回應 this
  止損: (最新, 回應)->
    @對策(最新, 回應)
  #為何不行? 應對: @止損
  ###
  應對: (最新, 回應)->
    @對策(最新, 回應)


### 目標證券群
  此處控制系統中同一個策略每一品種僅需一個object

  根據外部所提供行情,以及預定策略,實時決策操作
###
###
  @codes: ['135333','xxdge']
###
class Securities
  constructor:(@codes, @策略)->
    #console.log '初始代碼表:', @codes
    #@策略.準備()
    @品種={}
    for code in @codes
      @品種[code] = new Security(this, code, @策略)

  重載: (code)->
    @品種[code] = new Security(this, code, @策略)

  更新品種:(codes)->
    if codes?
      for code in codes
        unless code in @codes
          ### 須檢測 code 是否正常?
          #if code.length is 6
          ###
          @codes.push code
          @重載(code)

  應對: (jso, 回應)->
    # 不知為何出現一個代碼為sz的東西,未知bug出現在哪個環節
    for k, tick of jso
      code = tick.代碼
      unless code in @codes
        console.log 'securities 應對 新出現 tick.代碼:',code
        # 這是臨時使用的限制,由於發現在沒有獲得codes時,會出現'sz','szsz'這些代碼
        if code isnt 'sz'
          @codes.push code
          @品種[code] = new Security(this, code,@策略)
      # 這是臨時使用的限制,由於發現在沒有獲得codes時,會出現'sz','szsz'這些代碼
      if code isnt 'sz'
        @品種[code].應對(tick, 回應)

  clearIntervals: ->
    console.log 'securities>> clearIntervals'
    for each in @codes
      @品種[each].clearIntervals()

module.exports = Securities
