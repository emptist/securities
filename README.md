# serobot
其實是一組證券.
# 易犯錯誤
注意, @品種 是一個字典,而不是Array,因此不要直接用

  ```coffeescript
  for each in @品種
    'do something'
  ```

而要用

  ```coffeescript
  for each in @codes
    @品種[each]
  ```
# throw in JavaScript
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/throw
