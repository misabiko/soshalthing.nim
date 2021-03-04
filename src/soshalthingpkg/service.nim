import karax/reactive, asyncjs, article, tables

type
    RefreshProc* = proc(
            articles: ArticleCollection,
            timelineArticles: var RSeq[string],
            bottom: bool,
            options: TableRef[string, string]
        ): Future[system.void]
    EndpointInfo* = ref object of RootObj
        name*: string
        refresh*: RefreshProc
        isReady*: proc(): bool
    ServiceInfo* = ref object
        endpoints*: seq[EndpointInfo]
        articles*: ArticleCollection

proc newService*(endpoints: seq[EndpointInfo]): ServiceInfo =
    return ServiceInfo(
        endpoints: endpoints,
        articles: newOrderedTable[string, ArticleData](),
    )