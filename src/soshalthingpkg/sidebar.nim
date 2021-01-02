import karax / [vdom, karaxdsl]

proc sidebar*(): VNode =
    result = buildHtml(nav(id = "sidebar")):
        tdiv(id = "sidebarButtons")