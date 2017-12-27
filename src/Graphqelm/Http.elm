module Graphqelm.Http exposing (Error, Request, buildMutationRequest, buildQueryRequest, send, toRequest, withHeader, withTimeout)

{-| Send requests to your GraphQL endpoint. See the `examples/` folder for an end-to-end example.
The builder syntax is inspired by Luke Westby's
[elm-http-builder package](http://package.elm-lang.org/packages/lukewestby/elm-http-builder/latest).

@docs buildQueryRequest, buildMutationRequest, send, toRequest, withHeader, withTimeout
@docs Request, Error

-}

import Graphqelm exposing (RootMutation, RootQuery)
import Graphqelm.Document as Document
import Graphqelm.Document.LowLevel as Document
import Graphqelm.Parser.Response
import Graphqelm.SelectionSet exposing (SelectionSet)
import Http
import Json.Decode
import Json.Encode
import Time exposing (Time)


{-| TODO
-}
type Request decodesTo
    = Request
        { method : String
        , headers : List Http.Header
        , url : String
        , body : Http.Body
        , expect : Json.Decode.Decoder decodesTo
        , timeout : Maybe Time
        , withCredentials : Bool
        }


{-| TODO
-}
buildRequest : String -> String -> SelectionSet decodesTo typeLock -> Request decodesTo
buildRequest url queryDocument query =
    { method = "POST"
    , headers = []
    , url = url
    , body = Http.jsonBody (Json.Encode.object [ ( "query", Json.Encode.string queryDocument ) ])
    , expect = Document.decoder query
    , timeout = Nothing
    , withCredentials = False
    }
        |> Request


{-| TODO
-}
buildQueryRequest : String -> SelectionSet decodesTo RootQuery -> Request decodesTo
buildQueryRequest url query =
    buildRequest url (Document.serializeQuery query) query


{-| TODO
-}
buildMutationRequest : String -> SelectionSet decodesTo RootMutation -> Request decodesTo
buildMutationRequest url query =
    buildRequest url (Document.serializeMutation query) query


{-| TODO
-}
type Error
    = GraphQLError (List Graphqelm.Parser.Response.Error)
    | HttpError Http.Error


type SuccessOrError a
    = Success a
    | ErrorThing (List Graphqelm.Parser.Response.Error)


convertResult : Result Http.Error (SuccessOrError a) -> Result Error a
convertResult httpResult =
    case httpResult of
        Ok successOrError ->
            case successOrError of
                Success value ->
                    Ok value

                ErrorThing error ->
                    Err (GraphQLError error)

        Err httpError ->
            Err (HttpError httpError)


{-| Send the `Graphqelm.Request`
-}
send : (Result Error a -> msg) -> Request a -> Cmd msg
send resultToMessage graphqelmRequest =
    graphqelmRequest
        |> toRequest
        |> Http.send (convertResult >> resultToMessage)


{-| Convert to a `Graphqelm.Http.Request` to an `Http.Request`.
Useful for using libraries like
[RemoteData](http://package.elm-lang.org/packages/krisajenkins/remotedata/latest/).

    makeRequest : Cmd Msg
    makeRequest =
        query
            |> Graphqelm.Http.buildQueryRequest "http://localhost:4000/api"
            |> Graphqelm.Http.toRequest
            |> RemoteData.sendRequest
            |> Cmd.map GotResponse

-}
toRequest : Request decodesTo -> Http.Request (SuccessOrError decodesTo)
toRequest (Request request) =
    { request | expect = Http.expectJson (decoderOrError request.expect) }
        |> Http.request


decoderOrError : Json.Decode.Decoder a -> Json.Decode.Decoder (SuccessOrError a)
decoderOrError decoder =
    Json.Decode.oneOf
        [ decoder |> Json.Decode.map Success
        , Graphqelm.Parser.Response.errorDecoder |> Json.Decode.map ErrorThing
        ]


{-| Add a header.
-}
withHeader : String -> String -> Request decodesTo -> Request decodesTo
withHeader key value (Request request) =
    Request { request | headers = Http.header key value :: request.headers }


{-| Add a timeout.
-}
withTimeout : Time -> Request decodesTo -> Request decodesTo
withTimeout timeout (Request request) =
    Request { request | timeout = Just timeout }


{-| Set with credentials to true.
-}
withCredentials : Request decodesTo -> Request decodesTo
withCredentials (Request request) =
    Request { request | withCredentials = True }
