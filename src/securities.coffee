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
  constructor: (@代碼,@策略,@百分比=0.0618)->
    ### 經過如下處理,@對策 function中的this即此證券品種
    ###
    @對策 = @策略.對策

    ### 在此取得行情,準備好天地線和頂底指標,
      也可在 observer中做.好處是此處不用再改寫.
      每隔 n分鐘更新一次 n分鐘數據
    ###
    hists {symbol: @代碼, type:'m05'},(err,arr)=>
      unless err
        pool = new 池()
        @五分鐘線池 = pool.序列(arr)

        updateM05 = ->
          hists {symbol: @代碼, type:'m05',len:1},(err,arr) ->
            unless err
              unless arr[0].day is @五分鐘線池.燭線[-1..][0].day
                @五分鐘池.新增 arr[0]

        @iM05 = setInterval updateM05, 5*分鐘

      ### TODO:
        出錯時換一個數據源再嘗試
      ###


    # 每一周的週五更新週線數據
    hists {symbol: @代碼, type:'week'},(err,arr)=>
      unless err
        pool = new 池()
        @週線池 = pool.序列(arr)
      ### TODO:
        出錯時換一個數據源再嘗試
      ###
      # 用週線確定所需的行情片段再獲取日線,以免數據太大
      # 每隔24小時,在閉市期間更新一次日線數據

      hists {symbol: @代碼, type:'day',len: 5 * @週線池.求主魚長()},(err,arr)=>
        unless err
          pool = new 池()
          @日線池 = pool.序列(arr)
        ### TODO:
          出錯時換一個數據源再嘗試
        ###


  clearIntervalM05: -> clearInterval @iM05
  clearIntervalDay: -> clearInterval @iDay
  clearIntervalWeek: -> clearInterval @iWeek

  clearIntervals: ->
    @clearIntervalM05()
    @clearIntervalDay()
    @clearIntervalWeek()

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
    #@策略.準備()
    @品種={}
    for 代碼 in @codes
      @品種[代碼] = new Security(代碼,@策略,0.618)

  應對: (jso, 回應)->
    for k, tick of jso
      代碼 = tick.代碼
      unless 代碼 in @codes
        @品種[代碼] = new Security(代碼,@策略,0.618)
      @品種[代碼].應對(tick, 回應)

  clearIntervals: ->
    for each in @品種
      each.clearIntervals()

module.exports = Securities
