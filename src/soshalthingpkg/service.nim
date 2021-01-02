import karax/[vdom, reactive], asyncjs

type
    RefreshProc* = proc(articles: var RSeq[string]): Future[system.void]
    EndpointInfo* = object
        onAdded: seq[proc()]
    ServiceInfo* = object
        toVNode*: proc(id: string): VNode
        refresh*: RefreshProc
        endpoints*: seq[EndpointInfo]