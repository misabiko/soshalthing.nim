import karax/[karax, vdom, karaxdsl], dom, timeline, twitter/service

let t = newTimeline("Home", TwitterService)
t.refresh()

proc createDom(): VNode =
    result = buildHtml(tdiv(id="timelineContainer")):
        t.timeline()

setRenderer createDom

# TODO refresh button
# TODO Obey the nimble gods
# TODO Serve css with right MIME
# TODO Split sass into subfiles
# TODO Move fontawesome to separate module