when defined(js):
    import karax/[karax, vdom, karaxdsl], dom, tables
    import soshalthingpkg / [timelines/timeline, sidebar/sidebar]
    import soshalthingpkg / [twitter/service, twitter/article]

    var timelines: seq[Timeline]
    timelines.add newTimeline("Home", TwitterService, 0, article.toVNode, 64285, container = basicSortedContainer())
    timelines.add newTimeline("Art", TwitterService, 3, article.toVNode, 9000, container = basicSortedContainer(), options = {"slug": "Art", "owner_screen_name": "misabiko"}.newTable)
    timelines.add newTimeline("1draw", TwitterService, 2, article.toVNode, 9000, container = basicSortedContainer(), options = {"q": "#深夜の真剣お絵描き60分一本勝負 OR #東方の90分お絵描き"}.newTable)
    timelines.add newTimeline("User", TwitterService, 1, article.toVNode, 9000, container = basicSortedContainer())

    proc createDom(): VNode =
        result = buildHtml(tdiv):
            sidebar()
            tdiv(id="timelineContainer"):
                for t in timelines.mitems:
                    t.timeline()

    setRenderer createDom

# TODO Move timeline refresh cooldown to endpoint
    # TODO Interval should be endpoint level, if one subscriber asks for it, and every subscriber should be updated
    # TODO If you have two timelines using the same endpoint and refresh one, both should update
# TODO Move timelines to json file
# TODO Login
# TODO Switch container
    # TODO Bring masonry in soshal
        # TODO Somehow add VNode width/height articles
# TODO Serve css with right MIME
# TODO Integrate serving to soshal
# TODO Handle server not responding
# TODO Get unit tests working on js
    # https://nim-lang.org/docs/testament.html