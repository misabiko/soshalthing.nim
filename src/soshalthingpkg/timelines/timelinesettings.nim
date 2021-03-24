import karax / [karax, karaxdsl, vdom, reactive], strutils, dom, tables
import timeline

proc articleClickSetting*(t: Timeline): VNode =
    buildHtml(tdiv(class = "select")):
        select(min = $ord(low(OnArticleClick)), max = $ord(high(OnArticleClick))):
            for clickAction in ord(low(OnArticleClick))..ord(high(OnArticleClick)):
                let selected = if clickAction == ord(t.onArticleClick):
                    cstring"selected"
                else:
                    cstring(nil)
                option(value = $clickAction, selected = selected):
                    text $OnArticleClick(clickAction)

            proc onchange(ev: Event; n: VNode) =
                let value = parseInt($ev.target.value)
                t.onArticleClick = OnArticleClick(value)

proc toChecked(checked: bool): cstring =
    (if checked: cstring"checked" else: cstring(nil))

proc infiniteLoadSetting*(t: Timeline): VNode =
    buildHtml(label(class = "checkbox")):
        input(`type` = "checkbox", checked = t.infiniteLoad.toChecked):
            proc onclick(ev: Event; n: VNode) =
                t.infiniteLoad = not t.infiniteLoad
        
        text "Infinite Load"

proc containerSetting*(t: Timeline): VNode =
    buildHtml(tdiv(class = "select")):
        select:
            for name in articlesContainers.keys:
                let selected = if t.container == name:
                    cstring"selected"
                else:
                    cstring(nil)

                option(value = name, selected = selected):
                    text name

            proc onchange(ev: Event; n: VNode) =
                t.container = articlesContainers[$ev.target.value]()

defaultSettings.add articleClickSetting
defaultSettings.add infiniteLoadSetting
defaultSettings.add containerSetting