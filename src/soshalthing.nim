when defined(js):
    import karax/[karax, vdom, karaxdsl], dom, strtabs, logging
    import soshalthingpkg / [timelines/timeline, sidebar/sidebar]
    import soshalthingpkg / timelines / [containers/basicContainer, containers/masonry, timelinesettings]
    import soshalthingpkg / [twitter/service, twitter/article]

    var consoleLog = newConsoleLogger()
    addHandler(consoleLog)

    var timelines: seq[Timeline]
    timelines.add newTimeline(
        "Home", "Twitter", 0,
        article.toVNode, article.toModal,
        interval = 64285,
    )
    timelines.add newTimeline(
        "Art", "Twitter", 3,
        article.toVNode, article.toModal,
        options = {"slug": "Art", "owner_screen_name": "misabiko"}.newStringTable,
        interval = 9000,
    )
    timelines[^1].articleFilters.add mediaFilter
    timelines.add newTimeline(
        "1draw", "Twitter", 2,
        article.toVNode, article.toModal,
        options = {
            "q": "-filter:retweets #深夜の真剣お絵描き60分一本勝負 OR #東方の90分お絵描き",
            "result_type": "recent"
        }.newStringTable,
        interval = 9000,
    )
    timelines[^1].articleFilters.add retweetFilter
    timelines.add newTimeline(
        "User", "Twitter", 1,
        article.toVNode, article.toModal,
        interval = 9000,
    )

    proc createDom(): VNode =
        result = buildHtml(tdiv):
            sidebar()
            tdiv(id="timelineContainer"):
                for t in timelines.mitems:
                    t.timeline()

    for t in timelines:
        discard t.refresh(ignoreTime = true)
    setRenderer createDom

# TODO Login
# TODO Move timelines to json file
# TODO Serve css with right MIME
# TODO Integrate serving to soshal
# TODO Handle server not responding
# TODO Use composition to standardize article like and share