import karax/[karax, karaxdsl, vdom, reactive], sequtils, sugar, algorithm, dom, strutils, tables, options
import ../timeline

type
    WheelEvent* = ref WheelEventObj ## see `docs<https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent>`_
    WheelEventObj {.importc.} = object of Event
        deltaX*, deltaY*, deltaZ*: float
        deltaMode*: int
    MasonryContainer* = ref object of ArticlesContainer
        colNum*: RInt
        squeezed*: RBool

proc masonrySettings*(t: Timeline): VNode =
    let container = t.container.MasonryContainer

    buildHtml(tdiv):
        input(class = "input", `type` = "number", value = $container.colNum.value, min = "1"):
            proc onchange(ev: Event; n: VNode) =
                let value = parseInt($ev.target.value)
                if value >= 1:
                    container.colNum <- value

        label(class = "checkbox"):
            input(`type` = "checkbox", checked = container.squeezed.value.toChecked):
                proc onclick(ev: Event; n: VNode) =
                    container.squeezed <- not container.squeezed.value
            
            text "Squeezed"

proc isScrolledIntoView(el: Node, container: Node): bool =
    let elRect = el.getBoundingClientRect()
    let cRect = container.getBoundingClientRect()

    # Only completely visible elements return true:
    result = elRect.top >= cRect.top and elRect.bottom <= cRect.bottom
    # Partially visible elements return true:
    #result = elRect.top < window.innerHeight && elRect.bottom >= 0

proc masonryContainer*(): ArticlesContainer =
    let toVNode = proc (c: ArticlesContainer, t: var Timeline): VNode =
        proc scrollEvent(ev: Event; n: VNode) =
            if not t.infiniteLoad:
                return
            
            let d = ev.currentTarget
            if d != nil:
                for i, c in d.children.pairs:
                    var
                        bottom = 0
                        top = 0
                        found = false
                    for a in c.children:
                        if a.isScrolledIntoView(d):
                            found = true
                        else:
                            if found:
                                bottom.inc
                            else:
                                top.inc
                    t.needTop <- (top <= 1)
                    t.needBottom <- (bottom <= 1)
        
        proc wheelEvent(ev: WheelEvent, n: VNode) =
            if not t.infiniteLoad:
                return
            
            let d = ev.deltaY
            if d < 0:
                if t.needTop.value:
                    discard t.refillTop()
            elif d > 0:
                if t.needBottom.value:
                    discard t.refillBottom()

        let container = c.MasonryContainer

        let nodes = collect(newSeq):
            for id in t.filteredArticles:
                let d = t.service.articles[id]

                if d.size.isSome:
                    let size = d.size.get()
                    (t.article(d.id), size.height.value / size.width.value)
                else:
                    (t.article(d.id), 1.float)

        var columns = newSeq[seq[(VNode, float)]](container.colNum.value)
        for i, n in nodes:
            var idc = collect(newSeqOfCap(container.colNum.value)):
                for idx, c in columns.pairs:
                    if c.len > 0:
                        (idx, c.map(proc(x: (VNode, float)): float = x[1]).foldl(a + b))
                    else:
                        (idx, 0.0)

            idc.sort(proc(x, y: auto): int = cmp(x[1], y[1]))
            columns[idc[0][0]].add(n)

        var masonryClass = "timelineArticles timelineMasonry"
        if container.squeezed.value:
            masonryClass &= " masonrySqueezed"

        buildHtml(tdiv(onscroll=scrollEvent, onwheel=wheelEvent, class = masonryClass)):
            for c in columns:
                tdiv(class="masonryColumn"):
                    for n in c: n[0]

    MasonryContainer(
        name: "Masonry",
        toVNode: toVNode,
        setting: some(masonrySettings.TimelineProc),
        colNum: 3.rint,
        squeezed: false.rbool,
    ).ArticlesContainer

articlesContainers["Masonry"] = masonryContainer