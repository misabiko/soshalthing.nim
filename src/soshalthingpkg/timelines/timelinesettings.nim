import karax / [karax, karaxdsl, vdom, reactive]
import timeline

proc timelineSettings*(t: Timeline): VNode =
    buildHtml(tdiv(class = "timelineOptions")):
        input(class = "input", `type` = "number", value = "5")