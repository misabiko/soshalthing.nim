import karax/[karax, reactive], asyncjs, article, tables, strformat

type
    EndpointPayload* = object
        articles*: seq[ArticleData]
        newArticles*: seq[string]
    RefreshOptions* = Table[string, RootRef]
    RefreshProc* = proc(bottom: bool, options: RefreshOptions): Future[EndpointPayload]
    EndpointInfo* = ref object of RootObj
        name*: string
        refreshProc*: RefreshProc #TODO Make private
        isReady*: proc(): bool
        subscribers*: seq[RSeq[string]]
    ServiceInfo* = ref object
        endpoints*: seq[EndpointInfo]
        articles*: ArticleCollection

var services*: TableRef[string, ServiceInfo] = newTable[string, ServiceInfo]()

proc addService*(name: string, service: ServiceInfo) = services[name] = service

proc newService*(endpoints: seq[EndpointInfo]): ServiceInfo =
    return ServiceInfo(
        endpoints: endpoints,
        articles: newOrderedTable[string, ArticleData](),
    )

proc newEndpoint*(name: string, refresh: RefreshProc, isReady: proc(): bool): EndpointInfo =
    EndpointInfo(name: name, refreshProc: refresh, isReady: isReady)

proc refreshEndpoint*(s: ServiceInfo, index: int, bottom: bool, options: RefreshOptions) {.async.} =
    let payload = await s.endpoints[index].refreshProc(bottom, options)

    let direction = if bottom: "down" else: "up"
    echo &"Refreshed {s.endpoints[index].name} {direction} - {$payload.newArticles.len} articles"

    for article in payload.articles:
        s.articles.update(article.id, article)

    echo "Service has " & $s.articles.len & " articles"

    for subscriberArticles in s.endpoints[index].subscribers:
        for articleId in payload.newArticles:
            if articleId notin subscriberArticles:
                subscriberArticles.add(articleId)

    redraw()