when defined(js):
    import karax/[karax, vdom, karaxdsl], dom, tables
    import soshalthingpkg / [timeline, sidebar/sidebar, twitter/service, twitter/article]

    var timelines: seq[Timeline]
    timelines.add newTimeline("Home", TwitterService, 0, article.toVNode, container = basicSortedContainer())
    timelines.add newTimeline("Art", TwitterService, 3, article.toVNode, container = basicSortedContainer(), options = {"slug": "Art", "owner_screen_name": "misabiko"}.newTable)
    timelines.add newTimeline("1draw", TwitterService, 2, article.toVNode, container = basicSortedContainer(), options = {"q": "#深夜の真剣お絵描き60分一本勝負 OR #東方の90分お絵描き"}.newTable)
    timelines.add newTimeline("User", TwitterService, 1, article.toVNode, container = basicSortedContainer())

    proc createDom(): VNode =
        result = buildHtml(tdiv):
            sidebar()
            tdiv(id="timelineContainer"):
                for t in timelines.mitems:
                    t.timeline()

    setRenderer createDom

# TODO Interval refresh
# TODO Login
# TODO Switch container
    # Bring masonry in soshal
# TODO Have an event add new articles to timeline
    # If you have two timelines using the same endpoint and refresh one, both should update
# TODO Serve css with right MIME
# TODO Move fontawesome to separate module
# TODO Handle server not responding