module Api.Object.PullRequestConnection exposing (..)

import Api.Object
import Graphqelm.Argument as Argument exposing (Argument)
import Graphqelm.Field as Field exposing (Field, FieldDecoder)
import Graphqelm.Object as Object exposing (Object)
import Json.Decode as Decode


build : (a -> constructor) -> Object (a -> constructor) Api.Object.PullRequestConnection
build constructor =
    Object.object constructor


edges : Object edges Api.Object.PullRequestEdge -> FieldDecoder (List edges) Api.Object.PullRequestConnection
edges object =
    Object.listOf "edges" [] object


nodes : Object nodes Api.Object.PullRequest -> FieldDecoder (List nodes) Api.Object.PullRequestConnection
nodes object =
    Object.listOf "nodes" [] object


pageInfo : Object pageInfo Api.Object.PageInfo -> FieldDecoder pageInfo Api.Object.PullRequestConnection
pageInfo object =
    Object.single "pageInfo" [] object


totalCount : FieldDecoder Int Api.Object.PullRequestConnection
totalCount =
    Field.fieldDecoder "totalCount" [] Decode.int