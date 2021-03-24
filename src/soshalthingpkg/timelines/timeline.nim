import karax / [karax, karaxdsl, vdom, reactive], times, asyncjs, strformat, tables, dom, strtabs, options, logging
import ../service, ../article, ../fontawesome

type
    TimelineProc* = proc(t: Timeline): VNode
    ToVNodeProc* = proc(t: Timeline, id: string): VNode
    OnArticleClick* {.pure.} = enum
        Hide, Expand, Like, Nothing
    ArticlesContainer* = ref object of RootObj
        toVNode*: proc(c: ArticlesContainer, t: var Timeline): VNode
        setting*: Option[TimelineProc]
    Timeline* = ref object of RootObj
        name*: string
        articles*: RSeq[string]
        serviceName*: string
        toVNode*, toModal*: ToVNodeProc
        endpointIndex*: int
        options*: StringTableRef
        container*: ArticlesContainer
        lastBottomRefresh*, lastTopRefresh*: Time
        infiniteLoad*, loadingTop*, loadingBottom*: bool
        needTop*, needBottom*, showHidden*, showOptions*: RBool
        doneTop*, doneBottom*: bool
        onArticleClick*: OnArticleClick
        settings*: seq[TimelineProc]
        modalId*: RString
        refreshInterval*: ref Interval
        articleFilters*: seq[proc(a: ArticleData): bool]
        baseOptions*: RefreshOptions

var defaultContainer*: string
var articlesContainers* = newTable[string, proc(): ArticlesContainer]()

var defaultSettings*: seq[TimelineProc]

let minRefreshDelay = initDuration(seconds = 1)

proc service*(t: Timeline): ServiceInfo = services[t.serviceName]

# TODO Get rid of Timeline.article()
proc article*(t: Timeline, id: string): VNode = t.toVNode(t, id)

proc endpoint*(t: Timeline): EndpointInfo = t.service.endpoints[t.endpointIndex]

proc filteredArticles*(t: Timeline): seq[string] =
    for i in 0..<len(t.articles):
        let id = t.articles[i]
        if not t.showHidden.value and t.service.articles[id].hidden.value:
            continue
        block innerloop:
            for filter in t.articleFilters:
                if not filter(t.service.articles[id]):
                    break innerloop
                
            result.add(id)

proc isRefreshingTooFast*(t: Timeline, bottom: bool, now = getTime()): bool =
    if bottom:
        if now - t.lastBottomRefresh < minRefreshDelay:
            return true
    else:
        if now - t.lastTopRefresh < minRefreshDelay:
            return true
    
    false

proc updateTime*(t: Timeline, bottom: bool, now = getTime()) =
    if bottom:
        t.lastBottomRefresh = now
    else:
        t.lastTopRefresh = now

method refresh*(t: Timeline, bottom = true, ignoreTime = false) {.async, base.} =
    if not t.endpoint.isReady():
        notice(t.name & "'s endpoint is over limit.")
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

    var refreshOptions: RefreshOptions
    for k, v in t.baseOptions.pairs:
        refreshOptions[k] = v
    refreshOptions["options"] = t.options
    let payload = await t.service.refreshEndpoint(t.endpointIndex, bottom, refreshOptions)

    if payload.doneBottom:
        info(t.name & " done with bottom")
        t.doneBottom = true
    if payload.doneTop:
        info(t.name & " done with top")
        t.doneTop = true

    t.updateTime(bottom)

proc refillTop*(t: var Timeline) {.async.} =
    if t.loadingTop or t.doneTop:
        return
    
    t.loadingTop = true
    if not t.isRefreshingTooFast(false):
        info(&"Refilling {t.name} top")
        await t.refresh(false)
    t.loadingTop = false

proc refillBottom*(t: var Timeline) {.async.} =
    if t.loadingBottom or t.doneBottom:
        return
    
    t.loadingBottom = true
    if not t.isRefreshingTooFast(true):
        info(&"Refilling {t.name} bottom")
        await t.refresh()
    t.loadingBottom = false

proc articleClick*(t: Timeline, id: string) =
    case t.onArticleClick:
        of Hide:
            t.service.articles[id].hidden <- not t.service.articles[id].hidden.value
        of Expand:
            t.modalId <- id
        else:
            discard

proc newTimeline*(
        name: string,
        serviceName: string,
        endpointIndex: int,
        toVNode, toModal: ToVNodeProc,
        container = defaultContainer,
        options = newStringTable(),
        infiniteLoad = false,
        interval = 0,
        baseOptions = RefreshOptions(),
    ): Timeline =
    let now = getTime()
    result = Timeline(
        name: name,
        articles: newRSeq[string](),
        serviceName: serviceName,
        endpointIndex: endpointIndex,
        toVNode: toVNode,
        toModal: toModal,
        options: options,
        container: articlesContainers[container](),
        infiniteLoad: infiniteLoad,
        lastBottomRefresh: now,
        needTop: true.rbool,
        needBottom: false.rbool,
        showHidden: false.rbool,
        showOptions: false.rbool,
        modalId: "".rstr,
        baseOptions: baseOptions,
    )
    result.service.endpoints[endpointIndex].subscribers.add(result.articles)

    for setting in defaultSettings:
        result.settings.add setting

    if interval != 0:
        result.refreshInterval = window.setInterval(proc() = discard result.refresh(false), interval)

proc leftHeaderButtons*(t: var Timeline): seq[VNode] =
    discard

proc headerButtons*(t: var Timeline): seq[VNode] =
    result.add do:
        buildHtml(button()):
            icon("fa-sync-alt", size = "fa-lg")

            proc onclick() = discard t.refresh(ignoreTime = true)
    
    result.add do:
        buildHtml(button()):
            icon("fa-ellipsis-v", size = "fa-lg")

            proc onclick() = t.showOptions <- not t.showOptions.value

proc articleModal*(t: Timeline, id: string): VNode = t.toModal(t, id)

proc modal(t: Timeline): VNode =
    let modalActivated = t.modalId.value.len > 0
    buildHtml(tdiv(class = "modal" & (if modalActivated: " is-active" else: ""))):
        tdiv(class = "modal-background")
        tdiv(class = "modal-content"):
            if modalActivated:
                t.articleModal($t.modalId.value)
        button(class = "modal-close is-large", `aria-label` = "close")

        proc onclick() =
            t.modalId <- ""

proc timeline*(t: var Timeline, class = "timeline", hButtons = headerButtons(t), lhButtons = leftHeaderButtons(t)): VNode =
    var headerClass = "timelineHeader"
    if not t.endpoint.isReady():
        headerClass &= " timelineInvalid"

    buildHtml(section(class = class)):
        t.modal()
        tdiv(class = headerClass):
            tdiv(class="timelineLeftHeader"):
                strong: text t.name
                tdiv(class="timelineButtons"):
                    for b in lhButtons:
                        b

            tdiv(class="timelineButtons"):
                for b in hButtons:
                    b
        
        if t.showOptions.value:
            tdiv(class = "timelineOptions"):
                for settingProc in t.settings:
                    t.settingProc()
                if t.container.setting.isSome:
                    let settingProc = t.container.setting.get()
                    t.settingProc()

        t.container.toVNode(t.container, t)
# TODO Clicking head button move individually