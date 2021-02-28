import karax / [vdom, karaxdsl]

proc sidebar*(): VNode =
    buildHtml(nav(id = "sidebar")):
        tdiv(id = "sidebarButtons")