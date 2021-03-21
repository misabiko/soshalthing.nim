when defined(js):
    import karax/[karax, vdom, karaxdsl], dom, strtabs
    import soshalthingpkg / [timelines/timeline, sidebar/sidebar]
    import soshalthingpkg / [twitter/service, twitter/article]

    var timelines: seq[Timeline]
    timelines.add newTimeline(
        "Home", "Twitter", 0,
        article.toVNode, article.toModal,
        container = basicSortedContainer(),
        interval = 64285,
    )
    timelines.add newTimeline(
        "Art", "Twitter", 3,
        article.toVNode, article.toModal,
        container = basicSortedContainer(),
        options = {"slug": "Art", "owner_screen_name": "misabiko"}.newStringTable,
        articleFilter = mediaFilter,
        interval = 9000,
    )
    timelines.add newTimeline(
        "1draw", "Twitter", 2,
        article.toVNode, article.toModal,
        container = basicSortedContainer(),
        options = {
            "q": "-filter:retweets #深夜の真剣お絵描き60分一本勝負 OR #東方の90分お絵描き",
            "result_type": "recent"
        }.newStringTable,
        articleFilter = retweetFilter,
        interval = 9000,
    )
    timelines.add newTimeline(
        "User", "Twitter", 1,
        article.toVNode, article.toModal,
        container = basicSortedContainer(),
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
# TODO Move timeline refresh cooldown to endpoint
    # TODO Interval should be endpoint level, if one subscriber asks for it, and every subscriber should be updated
    # TODO If you have two timelines using the same endpoint and refresh one, both should update
# TODO Move timelines to json file
# TODO Switch container
    # TODO Bring masonry in soshal
        # TODO Somehow add VNode width/height articles
# TODO Serve css with right MIME
# TODO Integrate serving to soshal
# TODO Handle server not responding
# TODO Use composition to standardize article like and share
# TODO Toggle refresh logs