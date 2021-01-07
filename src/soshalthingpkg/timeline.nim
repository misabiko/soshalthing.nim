import karax / [karax, karaxdsl, vdom, reactive], algorithm, times, asyncjs
import service

type
    ArticlesContainer* = proc(self: var Timeline): VNode
    Timeline* = object
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo
        container*: ArticlesContainer
        needTop*, needBottom*: bool

proc article(self: Timeline, id: string): VNode = self.service.toVNode(id)

proc basicContainer(self: var Timeline): VNode =
    vmap(self.articles, tdiv(class="timelineArticles"), self.article)

proc basicSortedContainer*(self: var Timeline): VNode =
    var copy: seq[string]
    for i in 0..<len(self.articles):
        copy.add(self.articles[i])
    copy.sort(proc(x, y: string): int = cmp(self.service.getData(y).creationTime, self.service.getData(x).creationTime))
    result = buildHtml(tdiv(class="timelineArticles")):
        for i in copy:
            self.article i

proc refresh*(self: Timeline) {.async.} =
    var a = self.articles
    await self.service.refresh a
    redraw()
    echo "Refreshing " & self.name & " - " & $a.len & " articles"

proc newTimeline*(name: string, service: ServiceInfo, container: ArticlesContainer = basicContainer): Timeline =
    result = Timeline(name: name, articles: newRSeq[string](), service: service, container: container)
    discard result.refresh()

proc timeline*(self: var Timeline, class = "timeline"): VNode =
    result = buildHtml(section(class = class)):
        tdiv(class = "timelineHeader"):
            strong: text self.name & " " & $self.needTop & " " & $self.needBottom

            tdiv(class="timelineButtons"):
                button(class="refreshTimeline"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-sync-alt")

                    proc onclick() = discard self.refresh()
                button(class="openTimelineOptions"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-ellipsis-v")
        
        self.container(self)

# TODO Clicking head button move individually