import karax / [karaxdsl, vdom], algorithm, tables, times
import ../timeline

proc basicContainer*(): ArticlesContainer =
    let vnode = proc(c: ArticlesContainer, t: var Timeline): VNode =
        buildHtml(tdiv(class="timelineArticles")):
            for id in t.filteredArticles:
                t.article id

    ArticlesContainer(toVNode: vnode)

articlesContainers["Basic"] = basicContainer

proc basicSortedContainer*(): ArticlesContainer =
    let vnode = proc(c: ArticlesContainer, t: var Timeline): VNode =
        var filtered = t.filteredArticles()
        filtered.sort(proc(x, y: string): int = cmp(t.service.articles[y].creationTime, t.service.articles[x].creationTime))
        
        return buildHtml(tdiv(class="timelineArticles")):
            for i in filtered:
                t.article i

    ArticlesContainer(toVNode: vnode)

articlesContainers["Basic Sorted"] = basicSortedContainer
defaultContainer = "Basic Sorted"