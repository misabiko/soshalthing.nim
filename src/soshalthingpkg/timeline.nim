import karax / [karax, karaxdsl, vdom, reactive], service, algorithm, times

type
    ArticlesContainer* = proc(self: Timeline): VNode
    Timeline* = object
        name*: string
        articles*: RSeq[string]
        service*: ServiceInfo
        container*: ArticlesContainer

proc article(self: Timeline, id: string): VNode = self.service.toVNode(id)

proc basicContainer(self: Timeline): VNode =
    vmap(self.articles, tdiv(class="timelineArticles"), self.article)

proc basicSortedContainer*(self: Timeline): VNode =
    var copy: seq[string]
    for i in 0..<len(self.articles):
        copy.add(self.articles[i])
    copy.sort(proc(x, y: string): int = cmp(self.service.getData(y).creationTime, self.service.getData(x).creationTime))
    result = buildHtml(tdiv(class="timelineArticles")):
        for i in copy:
            self.article i

proc refresh*(self: Timeline) =
    echo "Refreshing " & self.name
    var a = self.articles
    discard self.service.refresh(a)

proc newTimeline*(name: string, service: ServiceInfo, container: ArticlesContainer = basicContainer): Timeline =
    result = Timeline(name: name, articles: newRSeq[string](), service: service, container: container)
    result.refresh()

proc timeline*(self: Timeline, class = "timeline"): VNode =
    result = buildHtml(section(class = class)):
        tdiv(class = "timelineHeader"):
            strong: text self.name

            tdiv(class="timelineButtons"):
                button(class="refreshTimeline"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-sync-alt")

                    proc onclick() = self.refresh()
                button(class="openTimelineOptions"):
                    span(class="icon"):
                        italic(class="fas fa-lg fa-ellipsis-v")
        
        self.container(self)

# TODO Clicking head button move individually