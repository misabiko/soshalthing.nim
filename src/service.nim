import karax/[vdom, reactive], asyncjs

type
    RefreshProc* = proc(articles: var RSeq[string]): Future[system.void]
    ServiceInfo* = object
        toVNode*: proc(id: string): VNode
        refresh*: RefreshProc