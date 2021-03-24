import karax / [karax, karaxdsl, vdom, reactive], times, asyncjs, strformat, tables, dom, strtabs, options
import ../service, ../article, ../fontawesome

type
    TimelineProc* = proc(t: Timeline): VNode
    ToVNodeProc* = proc(t: Timeline, id: string): VNode
    OnArticleClick* {.pure.} = enum
        Hide, Expand, Like, Nothing
    ArticlesContainer* = ref object of RootObj
        toVNode*: proc(self: ArticlesContainer, t: var Timeline): VNode
        setting*: Option[TimelineProc]
    Timeline* = ref object of RootObj
        name*: string
        articles*: RSeq[string]
        serviceName*: string
        toVNode*, toModal*: ToVNodeProc
        endpointIndex*: int
        options*: StringTableRef
        container*: string
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
var articlesContainers* = newTable[string, ArticlesContainer]()

var defaultSettings*: seq[TimelineProc]

let minRefreshDelay = initDuration(seconds = 1)

proc service*(t: Timeline): ServiceInfo = services[t.serviceName]

# TODO Get rid of Timeline.article()
proc article*(self: Timeline, id: string): VNode = self.toVNode(self, id)

proc endpoint*(self: Timeline): EndpointInfo = self.service.endpoints[self.endpointIndex]

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

proc isRefreshingTooFast*(self: Timeline, bottom: bool, now = getTime()): bool =
    if bottom:
        if now - self.lastBottomRefresh < minRefreshDelay:
            return true
    else:
        if now - self.lastTopRefresh < minRefreshDelay:
            return true
    
    false

proc updateTime*(self: Timeline, bottom: bool, now = getTime()) =
    if bottom:
        self.lastBottomRefresh = now
    else:
        self.lastTopRefresh = now

method refresh*(self: Timeline, bottom = true, ignoreTime = false) {.async, base.} =
    if not self.endpoint.isReady():
        echo self.name & "'s endpoint is over limit."
        return

    let now = getTime()
    if not ignoreTime and self.isRefreshingTooFast(bottom, now):
        return
    self.updateTime(bottom, now)

    if bottom:
        if self.doneBottom:
            return
    elif self.doneTop:
        return

    var refreshOptions: RefreshOptions
    for k, v in self.baseOptions.pairs:
        refreshOptions[k] = v
    refreshOptions["options"] = self.options
    let payload = await self.service.refreshEndpoint(self.endpointIndex, bottom, refreshOptions)

    if payload.doneBottom:
        echo self.name & " done with bottom"
        self.doneBottom = true
    if payload.doneTop:
        echo self.name & " done with top"
        self.doneTop = true

    self.updateTime(bottom)

proc refillTop*(self: var Timeline) {.async.} =
    if self.loadingTop or self.doneTop:
        return
    
    self.loadingTop = true
    if not self.isRefreshingTooFast(false):
        echo &"Refilling {self.name} top"
        await self.refresh(false)
    self.loadingTop = false

proc refillBottom*(self: var Timeline) {.async.} =
    if self.loadingBottom or self.doneBottom:
        return
    
    self.loadingBottom = true
    if not self.isRefreshingTooFast(true):
        echo &"Refilling {self.name} bottom"
        await self.refresh()
    self.loadingBottom = false

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

    if interval != 0:
        result.refreshInterval = window.setInterval(proc() = discard result.refresh(false), interval)

proc leftHeaderButtons*(self: var Timeline): seq[VNode] =
    discard

proc headerButtons*(self: var Timeline): seq[VNode] =
    result.add do:
        buildHtml(button()):
            icon("fa-sync-alt", size = "fa-lg")

            proc onclick() = discard self.refresh(ignoreTime = true)
    
    result.add do:
        buildHtml(button()):
            icon("fa-ellipsis-v", size = "fa-lg")

            proc onclick() = self.showOptions <- not self.showOptions.value

proc articleModal*(self: Timeline, id: string): VNode = self.toModal(self, id)

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

proc timeline*(self: var Timeline, class = "timeline", hButtons = headerButtons(self), lhButtons = leftHeaderButtons(self)): VNode =
    var headerClass = "timelineHeader"
    if not self.endpoint.isReady():
        headerClass &= " timelineInvalid"

    let container = articlesContainers[self.container]

    buildHtml(section(class = class)):
        self.modal()
        tdiv(class = headerClass):
            tdiv(class="timelineLeftHeader"):
                strong: text self.name
                tdiv(class="timelineButtons"):
                    for b in lhButtons:
                        b

            tdiv(class="timelineButtons"):
                for b in hButtons:
                    b
        
        if self.showOptions.value:
            tdiv(class = "timelineOptions"):
                for settingProc in self.settings:
                    self.settingProc()
                if container.setting.isSome:
                    let settingProc = container.setting.get()
                    self.settingProc()

        container.toVNode(container, self)
# TODO Clicking head button move individually