import karax / [vdom, reactive], times

type
    ArticleData* = ref object of RootObj
        id*: string
        creationTime*: DateTime
        hidden*: RBool
    Article* = ref object of VNode
        articleId*: string