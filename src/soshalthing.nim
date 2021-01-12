when defined(js):
    import karax/[karax, vdom, karaxdsl], dom
    import soshalthingpkg / [timeline, sidebar, twitter/service]

    var timelines: seq[Timeline]
    timelines.add newTimeline("Home", TwitterService, container = basicSortedContainer)
    timelines.add newTimeline("User", TwitterService2, container = basicSortedContainer)

    proc createDom(): VNode =
        result = buildHtml(tdiv):
            sidebar()
            tdiv(id="timelineContainer"):
                for t in timelines.mitems:
                    t.timeline()

    setRenderer createDom

# TODO Show endpoint status
# TODO Match tweetdeck's home timeline
# TODO Have an event add new articles to timeline
    # If you have two timelines using the same endpoint and refresh one, both should update
# TODO Serve css with right MIME
# TODO Move fontawesome to separate module
# TODO Handle server not responding