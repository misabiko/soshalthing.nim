include karax / prelude
import dom, timeline

let t = Timeline(name: "Home", articles: @["0", "1", "2"])

proc createDom(): VNode =
    result = buildHtml(tdiv):
        t.timeline()

setRenderer createDom


# TODO Request home timeline
# TODO Render tweet VNode
# TODO Prune preludes