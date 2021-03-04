import karax / [vdom, reactive], times, tables

type
    ArticleCollection* = OrderedTableRef[string, ArticleData]
    ArticleData* = ref object of RootObj
        id*: string
        creationTime*: DateTime
        hidden*: RBool
    Article* = ref object of VNode
        articleId*: string

method update*(baseData, newData: ArticleData) {.base.} =
    baseData.creationTime = newData.creationTime

method update*(articles: ArticleCollection, id: string, newData: ArticleData) {.base.} =
    articles[id].update(newData)