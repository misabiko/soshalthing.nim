import karax / [karax, vdom, karaxdsl]

proc settings(name: string): VNode =
    buildHtml(tdiv(class = "box")):
        tdiv():
            p():
                text "endpoint"

proc servicemenu*(): VNode =
    buildHtml(tdiv(class = "sidebarMenu")):
        settings("boop")