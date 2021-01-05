import karax / vdom, times

type
    ArticleData* = object of RootObj
        id*: string
        creationTime*: DateTime
    Article* = ref object of VNode
        articleId*: string