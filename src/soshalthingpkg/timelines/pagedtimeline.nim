import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat, tables, options, strtabs
import timeline, ../article, ../service, containers/basicContainer

type
    PageNum* = ref object of RootObj
        value*: int
    PagedTimeline* = ref object of Timeline
        loadedPages*: seq[int]

proc newPageNum(value: int): PageNum =
    result = new(PageNum)
    result.value = value

proc newPagedTimeline*(
        name: string,
        serviceName: string,
        endpointIndex: int,
        toVNode, toModal: ToVNodeProc,
        container = defaultContainer,
        options = newStringTable(),
        infiniteLoad = false,
        interval = 0,
        baseOptions = RefreshOptions(),
        startPage = 0,
    ): PagedTimeline =
    #[result = newTimeline(
        name, serviceName,
        endpointIndex,
        toVNode,
        toModal,
        container,
        options,
        infiniteLoad,
        0,
        baseOptions,
    ).PagedTimeline]#
    let now = getTime()
    result = PagedTimeline(
        name: name,
        articles: newRSeq[string](),
        serviceName: serviceName,
        endpointIndex: endpointIndex,
        toVNode: toVNode,
        toModal: toModal,
        options: options,
        container: container,
        infiniteLoad: infiniteLoad,
        lastBottomRefresh: now,
        needTop: RBool(value: true),
        needBottom: RBool(value: false),
        showHidden: RBool(value: false),
        showOptions: RBool(value: false),
        modalId: "".rstr,
        baseOptions: baseOptions,
    )
    result.service.endpoints[endpointIndex].subscribers.add(result.articles)

    for setting in defaultSettings:
        result.settings.add setting

proc getNextTopPage*(loadedPages: seq[int]): Option[PageNum] =
    if loadedPages[0] == 0:
        return none(PageNum)
    else:
        return newPageNum(loadedPages[0] - 1).some

#TODO Get current page and find first unloaded page from there
proc getNextBottomPage*(loadedPages: seq[int]): Option[PageNum] =
    newPageNum(loadedPages[loadedPages.len - 1] + 1).some

proc getNextPage*(t: PagedTimeline, bottom: bool): Option[PageNum] =
    if t.loadedPages.len == 0:
        return newPageNum(0).some
    elif bottom:
        t.loadedPages.getNextBottomPage()
    else:
        t.loadedPages.getNextTopPage()

method refresh*(t: PagedTimeline, bottom = true, ignoreTime = false) {.async.} =
    if not t.endpoint.isReady():
        echo t.name & "'s endpoint is over limit."
        return

    let now = getTime()
    if not ignoreTime and t.isRefreshingTooFast(bottom, now):
        return
    t.updateTime(bottom, now)

    if bottom:
        if t.doneBottom:
            return
    elif t.doneTop:
        return

    let pageNum = t.getNextPage(bottom)
    if pageNum.isNone:
        return
    
    var refreshOptions: RefreshOptions
    for k, v in t.baseOptions.pairs:
        refreshOptions[k] = v
    refreshOptions["options"] = t.options
    refreshOptions["pageNum"] = pageNum.get()

    let payload = await t.service.refreshEndpoint(t.endpointIndex, bottom, refreshOptions)
    t.loadedPages.add(pageNum.get().value)

    if payload.doneBottom:
        echo t.name & " done with bottom"
        t.doneBottom = true
    if payload.doneTop:
        echo t.name & " done with top"
        t.doneTop = true

    t.updateTime(bottom)
    let direction = if bottom:
        "bottom"
    else:
        "top"

when isMainModule:
    assert @[].getNextBottomPage() == some(0)
    assert @[].getNextTopPage() == none(int)
    assert @[0, 1, 2].getNextBottomPage() == some(3)
    assert @[0, 1, 3, 5, 8].getNextBottomPage() == some(9)
    assert @[0, 1, 3, 5, 8, 9].getNextTopPage() == none(int)
