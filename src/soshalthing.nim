import karax/[karax, vdom, karaxdsl], dom, timeline, twitter/service

let t = newTimeline("Home", TwitterService)
t.refresh()

proc createDom(): VNode =
    result = buildHtml(tdiv):
        t.timeline()

setRenderer createDom


# TODO Obey the nimble gods
# TODO Serve css with right MIME