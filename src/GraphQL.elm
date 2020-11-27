module GraphQL exposing
    ( Response, Error, Path(..), QLRes(..), Res, Root
    , run, segment
    )

{-| An easy-to-use GraphQL library.


## Types

@docs Response, Error, Path, QLRes, Res, Root


## Functions

@docs run, segment

-}

import Dict exposing (Dict)
import Http
import Json.Decode exposing (..)
import Json.Encode as Encode


{-| GraphQL error type [spec](https://spec.graphql.org/June2018/#sec-Errors).
-}
type alias Error =
    { message : String
    , locations : Maybe (List Location)
    , path : Maybe (List Path)
    , extensions : Maybe (Dict String Value)
    }


{-| Path of the response field which experienced the error.
-}
type Path
    = PathKey String
    | PathItem Int


{-| Error location.
-}
type alias Location =
    { line : Int
    , column : Int
    }


{-| GraphQL data type [spec](https://spec.graphql.org/June2018/#sec-Data).
-}
type alias Res a =
    { data : Maybe (Root a)
    , errors : Maybe (List Error)
    }


{-| GraphQL response type [spec](https://spec.graphql.org/June2018/#sec-Response-Format).
-}
type alias Response a =
    Result Http.Error (Res a)


{-| Root data response.
-}
type alias Root a =
    { root : a
    }


{-| Type to expose several GraphQL response scenari.
-}
type QLRes a
    = ResHttpError Http.Error
    | ResOnlyErrors (List Error)
    | ResWithErrors (List Error) a
    | ResWithoutError a


{-| Run a GraphQL request.
-}
run :
    { query : String
    , headers : List Http.Header
    , url : String
    , root : String
    , decoder : Decoder a
    , variables : Maybe Value
    , on : Response a -> msg
    }
    -> Cmd msg
run { query, headers, root, decoder, variables, url, on } =
    Http.request
        { method = "POST"
        , headers = headers
        , url = url
        , body = body query (Maybe.withDefault Encode.null variables)
        , expect = Http.expectJson on (decoderRes root decoder)
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Convert a raw Graph `Response` to the more expressive type `QLRes`.
-}
segment : Response a -> QLRes a
segment raw =
    case raw of
        Ok res ->
            case res.data of
                Nothing ->
                    ResOnlyErrors (Maybe.withDefault [] res.errors)

                Just d ->
                    case res.errors of
                        Nothing ->
                            ResWithoutError d.root

                        Just e ->
                            ResWithErrors e d.root

        Err err ->
            ResHttpError err


body : String -> Value -> Http.Body
body query variables =
    Http.jsonBody <|
        Encode.object
            [ ( "query", Encode.string query )
            , ( "variables", variables )
            ]



--
-- Decoders
--


decoderRes : String -> Decoder a -> Decoder (Res a)
decoderRes root decoder =
    map2 Res
        (maybe (field "data" (decoderRoot root decoder)))
        (maybe (field "errors" (list decoderError)))


decoderRoot : String -> Decoder a -> Decoder (Root a)
decoderRoot root decoder =
    map Root (field root decoder)


decoderError : Decoder Error
decoderError =
    map4 Error
        (field "message" string)
        (maybe (field "locations" (list decoderLocation)))
        (maybe (field "path" (list decoderPath)))
        (maybe (field "extensions" (dict value)))


decoderPath : Decoder Path
decoderPath =
    oneOf
        [ map PathKey string
        , map PathItem int
        ]


decoderLocation : Decoder Location
decoderLocation =
    map2 Location
        (field "line" int)
        (field "column" int)
