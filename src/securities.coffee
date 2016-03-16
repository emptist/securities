{hists} = require 'sedata'
{池} = require 'seyy'

### 智能化的投資品種,
  根據行情結構,應對最新行情作出相應操作
  將逐步演化完善
  以下代碼等名目,僅僅是用於對接現有的Python接口,將來系統中都可以統一換成中文
###

秒 = 1000
分鐘 = 60*秒
小時 = 60*分鐘

class Security
  constructor: (master, @代碼,@策略,@百分比=0.0618)->
    if @代碼.length < 6
      console.error "#{@代碼} 代碼不對"
    ### 經過如下處理,@對策 function中的this即此證券品種
    ###
    @對策 = @策略.對策

    ### 在此取得行情,準備好天地線和頂底指標,
      也可在 observer中做.好處是此處不用再改寫.
      每隔 n分鐘更新一次 n分鐘數據
    ###
    代碼 = @代碼
    hists {symbol: 代碼, type:'m05'},(err,arr)=>
      #代碼 = @代碼
      unless err
        unless arr?
          ### 用週線確定所需的行情片段再獲取日線,以免數據太大
          # 每隔24小時,在閉市期間更新一次日線數據
          #
          排查發現個別品種下載數據會出錯
          ###

          console.error  "#{代碼} 5分鐘數據下載不到"

        if arr?.length > 0
          pool = new 池()
          @五分鐘線池 = pool.序列(arr)
          五分鐘線池 = @五分鐘線池
          updateM05 = ->
            hists {symbol: 代碼, type:'m05',len:1},(err,arr) ->
              unless err
                #console.log 代碼, arr
                if arr[0].day isnt 五分鐘線池.燭線[-1..][0].day
                  #console.log '正在更新五分鐘線池 securities updateM05'
                  五分鐘線池.新增 arr[0]

          #@iM05 = setInterval updateM05, 5*分鐘
          # 測試故將時間縮短
          @iM05 = setInterval updateM05, 5*分鐘

      ### TODO:
        出錯時換一個數據源再嘗試
      ###


    # 每一周的週五更新週線數據
    hists {symbol: @代碼, type:'week',len:1000},(err,arr)=>
      len = 0
      if err?
        i = master.codes.indexOf(@代碼)
        master.codes.splice(i, 1)
        console.error "securities.coffee >> 63: #{@代碼} 下載週線", err
      else if arr?.length > 0
        pool = new 池()
        @週線池 = pool.序列(arr)
        #console.log "#{@代碼},週線主魚長: #{len}"#,@週線池.求主魚()
        ### 用週線確定所需的行情片段再獲取日線,以免數據太大
        每隔24小時,在閉市期間更新一次日線數據
        排查發現個別品種下載數據會出錯
        ###
        len = @週線池.求主魚長()

      hists {symbol: @代碼, type:'day',len: len*5},(err,arr)=>
        if err?
          i = master.codes.indexOf(@代碼)
          master.codes.splice(i, 1)
          console.error "securities.coffee >> 81: #{@代碼} 下載日線 #{len*5}#{@代碼 in master.codes}", err
        else if arr?.length > 0
          pool = new 池()
          @日線池 = pool.序列(arr)
          #console.log "securities.coffee >>#{@代碼}, 日線池.陰魚.尾.均: #{@日線池.陰魚.尾.均}"


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
      @品種[code] = new Security(this, code, @策略, 0.618)

  更新品種:(codes)->
    if codes?
      for code in codes
        unless code in @codes
          ### 須檢測 code 是否正常?
          #if code.length is 6
          ###
          @codes.push code
          @品種[code] = new Security(this, code,@策略,0.618)

  應對: (jso, 回應)->
    # 不知為何出現一個代碼為sz的東西,未知bug出現在哪個環節
    for k, tick of jso
      code = tick.代碼
      unless code in @codes
        console.log 'securities 應對 新出現 tick.代碼:',code
        if code isnt 'sz'
          @codes.push code
          @品種[code] = new Security(this, code,@策略,0.618)
      if code isnt 'sz'
        @品種[code].應對(tick, 回應)

  clearIntervals: ->
    console.log 'securities>> clearIntervals'
    for each in @codes
      @品種[each].clearIntervals()

module.exports = Securities
