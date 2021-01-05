import karax/[vdom, reactive], asyncjs, article

type
    RefreshProc* = proc(articles: var RSeq[string]): Future[system.void]
    EndpointInfo* = object
        onAdded: seq[proc()]
    ServiceInfo* = object
        toVNode*: proc(id: string): VNode
        getData*: proc(id: string): ArticleData
        refresh*: RefreshProc
        endpoints*: seq[EndpointInfo]