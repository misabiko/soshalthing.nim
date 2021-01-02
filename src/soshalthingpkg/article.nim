import karax / vdom

type
    ArticleData* = object of RootObj
        id*: string
        creationTime*: string
    Article* = ref object of VNode
        articleId*: string