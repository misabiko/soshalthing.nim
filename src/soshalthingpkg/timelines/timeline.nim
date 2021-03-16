import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs, strformat, tables, strutils, dom
import ../service, ../article, ../fontawesome

type
    TimelineProc* = proc(t: Timeline): VNode
    ArticlesContainer* = ref object of RootObj
        toVNode*: proc(self: ArticlesContainer, t: var Timeline): VNode
    ToVNodeProc* = proc(t: Timeline, id: string): VNode
    OnArticleClick {.pure.} = enum
        Hide, Expand, Like, Nothing
    Timeline* = ref object of RootObj
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo
        toVNode*: ToVNodeProc
        endpointIndex*: int
        options*: TableRef[string, string]
        container*: ArticlesContainer
        lastBottomRefresh*, lastTopRefresh*: Time
        infiniteLoad*, loadingTop*, loadingBottom*: bool
        needTop*, needBottom*, showHidden*, showOptions*: RBool
        onArticleClick*: OnArticleClick
        settings*: seq[TimelineProc]
        modalId*: RString

let minRefreshDelay = initDuration(seconds = 1)

proc article*(self: Timeline, id: string): VNode = self.toVNode(self, id)

proc endpoint*(self: Timeline): EndpointInfo = self.service.endpoints[self.endpointIndex]

proc basicContainer*(): ArticlesContainer =
    let toVNode = proc(self: ArticlesContainer, t: var Timeline): VNode =
        vmap(t.articles, tdiv(class="timelineArticles"), t.article)

    ArticlesContainer(toVNode: toVNode)

proc basicSortedContainer*(): ArticlesContainer =
    let toVNode = proc(self: ArticlesContainer, t: var Timeline): VNode =
        var copy: seq[string]
        for i in 0..<len(t.articles):
            copy.add(t.articles[i])
        copy.sort(proc(x, y: string): int = cmp(t.service.articles[y].creationTime, t.service.articles[x].creationTime))
        result = buildHtml(tdiv(class="timelineArticles")):
            for i in copy:
                t.article i

    ArticlesContainer(toVNode: toVNode)

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

    await self.service.refreshEndpoint(self.endpointIndex, bottom, self.options)

    self.updateTime(bottom)

proc refillTop*(self: var Timeline) {.async.} =
    if self.loadingTop:
        return
    
    self.loadingTop = true
    if not self.isRefreshingTooFast(false):
        echo &"Refilling {self.name} top"
        await self.refresh(false)
    self.loadingTop = false

proc refillBottom*(self: var Timeline) {.async.} =
    if self.loadingBottom:
        return
    
    self.loadingBottom = true
    if not self.isRefreshingTooFast(true):
        echo &"Refilling {self.name} bottom"
        await self.refresh()
    self.loadingBottom = false

proc articleClickSetting*(t: Timeline): VNode =
    buildHtml(tdiv(class = "select")):
        select(min = $ord(low(OnArticleClick)), max = $ord(high(OnArticleClick))):
            for clickAction in ord(low(OnArticleClick))..ord(high(OnArticleClick)):
                let selected = if clickAction == ord(t.onArticleClick):
                    cstring"selected"
                else:
                    cstring(nil)
                option(value = $clickAction, selected = selected):
                    text $OnArticleClick(clickAction)

            proc onchange(ev: Event; n: VNode) =
                let value = parseInt($ev.target.value)
                t.onArticleClick = OnArticleClick(value)

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
        service: ServiceInfo,
        endpointIndex: int,
        toVNode: ToVNodeProc,
        container: ArticlesContainer = basicContainer(),
        options = newTable[string, string](),
        infiniteLoad = false
    ): Timeline =
    let now = getTime()
    result = Timeline(
        name: name,
        articles: newRSeq[string](),
        service: service,
        endpointIndex: endpointIndex,
        toVNode: toVNode,
        options: options,
        container: container,
        infiniteLoad: infiniteLoad,
        lastBottomRefresh: now,
        needTop: RBool(value: true),
        needBottom: RBool(value: false),
        showHidden: RBool(value: false),
        showOptions: RBool(value: false),
        modalId: "".rstr
    )
    service.endpoints[endpointIndex].subscribers.add(result.articles)

    result.settings.add(articleClickSetting)

    discard result.refresh(ignoreTime = true)

proc leftHeaderButtons*(self: var Timeline): seq[VNode] =
    discard

proc headerButtons*(self: var Timeline): seq[VNode] =
    result.add do:
        buildHtml(button()):
            icon("fa-infinity", size = "fa-lg")

            proc onclick() = self.infiniteLoad = not self.infiniteLoad

    result.add do:
        buildHtml(button()):
            icon("fa-sync-alt", size = "fa-lg")

            proc onclick() = discard self.refresh(ignoreTime = true)
    
    result.add do:
        buildHtml(button()):
            icon("fa-ellipsis-v", size = "fa-lg")

            proc onclick() = self.showOptions <- not self.showOptions.value

proc timeline*(self: var Timeline, class = "timeline", hButtons = headerButtons(self), lhButtons = leftHeaderButtons(self)): VNode =
    var headerClass = "timelineHeader"
    if not self.endpoint.isReady():
        headerClass &= " timelineInvalid"

    let modalActivated = self.modalId.value.len > 0
    buildHtml(section(class = class)):
        tdiv(class = "modal" & (if modalActivated: " is-active" else: "")):
            tdiv(class = "modal-background")
            tdiv(class = "modal-content"):
                if modalActivated:
                    self.article($self.modalId.value)
            button(class = "modal-close is-large", `aria-label` = "close")

            proc onclick() =
                self.modalId <- ""
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

        self.container.toVNode(self.container, self)

# TODO Clicking head button move individually
# TODO Consider using StringTable for options