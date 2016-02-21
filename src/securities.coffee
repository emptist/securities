{hists} = require 'sedata'
### 智能化的投資品種,
  根據行情結構,應對最新行情作出相應操作
  將逐步演化完善
  以下代碼等名目,僅僅是用於對接現有的Python接口,將來系統中都可以統一換成中文
###

class Security
  constructor: (@代碼,@策略,@百分比=0.0618)->
    #在此取得行情,準備好天地線和頂底指標,也可在 observer中做.好處是此處不用再改寫.
    hists {symbol: @代碼, type:'m05'},(err,json)=>
      @五分鐘線 = json unless err
      ### TODO:
        出錯時換一個數據源再嘗試
      ###
      #console.log @代碼
    #經過如下處理,@對策function中的this即此證券品種
    @對策 = @策略.對策

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


module.exports = Securities
