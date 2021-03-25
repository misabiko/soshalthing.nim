when defined(js):
    import karax/[karax, vdom, karaxdsl], dom, strtabs, logging, json
    import soshalthingpkg / [timelines/timeline, timelines/timelinejson, sidebar/sidebar]
    import soshalthingpkg / timelines / [containers/prelude, timelinesettings]
    import soshalthingpkg / [twitter/service, twitter/article]

    var consoleLog = newConsoleLogger()
    addHandler(consoleLog)

    const timelinesFile* = staticRead("../resources/timelines.json")

    var timelines = parseJson(timelinesFile).getTimelines()

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
# TODO Serve css with right MIME
# TODO Integrate serving to soshal
# TODO Handle server not responding
# TODO Use composition to standardize article like and share