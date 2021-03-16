import karax / [karax, vdom, karaxdsl]
import ../fontawesome
import servicemenu

var expanded = false

proc sidebar*(): VNode =
    buildHtml(nav(id = "sidebar")):
        if expanded:
            servicemenu()
        tdiv(id = "sidebarButtons"):
            button(class="refreshTimeline"):
                icon("fa-angle-double-" & (if expanded: "left" else: "right"), size = "fa-2x")

                proc onclick() = expanded = not expanded