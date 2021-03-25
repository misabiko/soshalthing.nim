import karax / [vdom, karaxdsl], json, strtabs, tables
import timeline
import soshalthingpkg / [twitter/service, twitter/article]

proc filterSetting(name: string): TimelineProc =
    return proc(t: Timeline): VNode =
        text(name)

let filters = {
    "mediaFilter": ArticlesFilter(
        filter: mediaFilter,
        setting: filterSetting("mediaFilter"),
    ),
    "retweetFilter": ArticlesFilter(
        filter: retweetFilter,
        setting: filterSetting("retweetFilter"),
    )
}.toTable

proc getTimeline*(json: JsonNode): Timeline =
    var options = newStringTable()
    if "options" in json:
        for key, option in json["options"].pairs:
            options[key] = option.getStr()

    result = newTimeline(
        json["name"].getStr(),
        json["service"].getStr(),
        json["endpointIndex"].getInt(),
        article.toVNode, article.toModal,
        options = options,
        interval = json["interval"].getInt(0),
    )

    if "filters" in json:
        for filter in json["filters"]:
            result.articleFilters.add filters[filter.getStr()]

proc getTimelines*(json: JsonNode): seq[Timeline] =
    for t in json:
        result.add t.getTimeline()