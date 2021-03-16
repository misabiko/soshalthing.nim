import karax / [vdom, karaxdsl], strformat

proc icon*(icon: string, iconType = "fas", size = ""): VNode =
    buildHtml(span(class="icon")):
        italic(class = &"fas {size} {icon}")