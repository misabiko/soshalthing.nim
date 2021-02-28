import karax / [karax, vdom, karaxdsl]
import servicemenu

var expanded = false

proc sidebar*(): VNode =
    buildHtml(nav(id = "sidebar")):
        if expanded:
            servicemenu()
        tdiv(id = "sidebarButtons"):
            button(class="refreshTimeline"):
                span(class="icon"):
                    italic(class="fas fa-2x fa-angle-double-" & (if expanded: "left" else: "right"))

                proc onclick() = expanded = not expanded