import karax / vdom, times

type
    ArticleData* = ref object of RootObj
        id*: string
        creationTime*: DateTime
    Article* = ref object of VNode
        articleId*: string