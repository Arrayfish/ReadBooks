# Event modifiers

## [Event: preventDefault()](https://developer.mozilla.org/ja/docs/Web/API/Event/preventDefault)


規定のアクション(チェックボックス, テキストボックスへの入力)を行うのを妨げる。  
stopPropagation()などで伝播を妨げられない限り伝播する。  

例:
```js
const checkbox = document.querySelector("#id-checkbox");

checkbox.addEventListener("click", checkboxClick, false);

function checkboxClick(event) {
  let warn = "preventDefault() がこのチェックを妨害しています。<br>";
  document.getElementById("output-box").innerHTML += warn;
  event.preventDefault();
}

```

```html
<p>チェックボックスコントロールをクリックしてください。</p>

<form>
  <label for="id-checkbox">チェックボックス:</label>
  <input type="checkbox" id="id-checkbox" />
</form>

<div id="output-box"></div>

```

## [Event: stopPropagation()](https://developer.mozilla.org/ja/docs/Web/API/Event/stopPropagation)

イベントの伝播を妨げる。
現在のイベントは阻害しない。
現在のイベントを阻害する場合は上の`preventDefault()`を使用する。

## 