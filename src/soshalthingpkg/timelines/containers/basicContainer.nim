import karax / [karax, karaxdsl, vdom, reactive], algorithm, tables, times
import ../timeline

proc basicContainer*(): ArticlesContainer =
    let vnode = proc(self: ArticlesContainer, t: var Timeline): VNode =
        buildHtml(tdiv(class="timelineArticles")):
            for id in t.filteredArticles:
                t.article id

    ArticlesContainer(toVNode: vnode)

articlesContainers.add basicContainer()

proc basicSortedContainer*(): ArticlesContainer =
    let vnode = proc(self: ArticlesContainer, t: var Timeline): VNode =
        let filtered = t.filteredArticles()
        var copy: seq[string]
        for id in filtered:
            copy.add(id)
        copy.sort(proc(x, y: string): int = cmp(t.service.articles[y].creationTime, t.service.articles[x].creationTime))
        result = buildHtml(tdiv(class="timelineArticles")):
            for i in copy:
                t.article i

    ArticlesContainer(toVNode: vnode)

articlesContainers.add basicSortedContainer()