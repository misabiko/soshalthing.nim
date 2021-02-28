import karax / [karax, vdom, karaxdsl]

var expanded = false

proc sidebar*(): VNode =
    buildHtml(nav(id = "sidebar")):
        tdiv(id = "sidebarButtons"):
            button(class="refreshTimeline"):
                span(class="icon"):
                    italic(class="fas fa-2x fa-angle-double-right")

                proc onclick() =
                    echo "EXPAND"