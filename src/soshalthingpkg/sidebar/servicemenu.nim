import karax / [vdom, karaxdsl], tables
import ../twitter/service

proc settings(name: string): VNode =
    buildHtml(tdiv(class = "box")):
        text "Twitter"

        for endpoint, rate in rateLimits.pairs:
            tdiv:
                p: text endpoint
                progress(class = "progress is-primary", value = $rate.remaining, max = $rate.limit):
                    span: text $rate.remaining & "/" & $rate.limit
                p: text "Reset: " & $rate.reset

proc servicemenu*(): VNode =
    buildHtml(tdiv(class = "sidebarMenu")):
        settings("boop")