module GraphQL exposing
  (Config, Purpose, Response, exec, query, cmd, variables, decoder, response)

{-| Library to use GraphQL API easily.

Example to configure the API with a token in the `authorization` header:

  config : String -> GraphQL.Config
  config token =
    GraphQL.Config [ ("authorization", token) ] "/api/graphql"


Example to create a request:

  getUsers : String -> (GraphQL.Purpose Users -> msg) -> Cmd msg
  getUsers token resultCallback =
    GraphQL.cmd (myRequest token) resultCallback


  myRequest : String -> Http.Request (GraphQL.Response Users)
  myRequest token =
    GraphQL.exec (config token) "users"
      |> GraphQL.query myQuery
      |> GraphQL.variabes Encode.null
      |> GraphQL.decoder User.usersDecoder


  myQuery : String
  myQuery =
    """
    query {
      users { id login firstname lastname email }
    }
    """


Example to get the results:

  type Msg
    = GetUsers                    -- msg to execute the request
    | OnGetUsers (GraphQL.Purpose Users)  -- msg to receive the data
    ...

  update : Msg -> Model -> (Model, Cmd Msg)
  update msg model =
    case msg of
      GetUsers -> getUsers "myToken" OnGetUsers
      OnGetUsers res -> GraphQL.response model res
        (\users -> { model | ... } ! [ ... ] )    -- if success
        (\error -> { model | ... } ! [ ... ] )    -- if error


## Types
@docs Config, Purpose, Response

## Functions
@docs exec, query, cmd, variables, decoder, response
-}

import Http
import Http exposing (Request, send, request, header, expectJson)
import Json.Encode exposing (object, string, Value)
import Json.Decode exposing (Decoder)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional)


{-| Configure the headers and the url to use the GraphQL API.

Example for an API with JWT token:

  config : String -> GraphQL.Config
  config token =
    GraphQL.Config [ ("authorization", "Bearer " ++ token) ] "/api/graphql"

-}
type alias Config =
  { headers: List (String, String)
  , url: String
  }


{-| GraphQL response:
```
{
  data: { <query>: <result>|null },
  errors: [
    { message: ... }, ...
  ]
}
```
If there is a GraphQL error:
- the status code is **200**
- the `data` property is null
- the `errors` array is not empty.
-}
type alias Response a = GraphQl (Maybe a)


{-| Full API response.

There are two types of errors with the GraphQL:
- the GraphQL error (see `Response` type)
- the HTTP error.

`Purpose` is an abstraction for these 2 types of errors.
-}
type alias Purpose a = Result Http.Error (Result String a)


{-| Create a GraphQL request.

Example:

  myRequest : String -> Http.Request (GraphQL.Response Users)
  myRequest token =
    GraphQL.exec (config token) "users"
      |> GraphQL.query myQuery
      |> GraphQL.variabes Encode.null
      |> GraphQL.decoder User.usersDecoder
-}
exec : Config -> String -> String -> Value -> Decoder a -> Request (Response a)
exec config name query variables decoder  =
  request
    { method = "POST"
    , headers = List.map (\(name, value) -> header name value) config.headers
    , url = config.url
    , body = body query variables
    , expect = expectJson (graphqlDecoder name decoder)
    , timeout = Nothing
    , withCredentials = False
    }


{-| Helper to set the query for the GraphQL request in `exec`. -}
query : String -> (String -> Value -> Decoder a -> Request (Response a)) -> Value -> Decoder a -> Request (Response a)
query = (|>)


{-| Helper to set the query variables for the GraphQL request in `exec`. -}
variables : Value -> (Value -> Decoder a -> Request (Response a)) -> Decoder a -> Request (Response a)
variables = (|>)


{-| Helper to set the JSON decoder for the GraphQL request response in `exec`. -}
decoder : Decoder a -> (Decoder a -> Request (Response a)) -> Request (Response a)
decoder = (|>)


{-| Create a `Cmd` with the GraphQL request create with `exec`.

Example

  getUsers : String -> (GraphQL.Purpose Users -> msg) -> Cmd msg
  getUsers token resultCallback =
    GraphQL.cmd (myRequest token) resultCallback
-}
cmd : Request (Response a) -> (Purpose a -> msg) -> Cmd msg
cmd reqFunc resultFunc =
  send (resultFunc << (Result.map (\res ->
    case res.data.sub of
      Nothing ->
        let
          msg = String.join "\n" <| List.map (.message) res.errors
        in
          Err msg
      Just r -> Ok r
  ))) reqFunc


{-| Helper to parse the GraphQL response.

Example:
  update : Msg -> Model -> (Model, Cmd Msg)
  update msg model =
    case msg of
      ...
      OnGetUsers res -> GraphQL.response model res
        (\users -> { model | users = users, success = Just "get all users" } ! [] )
        (\error -> { model | error = Just error } ! [] )
-}
response : model -> Purpose data -> (data -> (model, Cmd msg) ) -> (String -> (model, Cmd msg)) -> (model, Cmd msg)
response model rep okFunc errFunc  =
  case rep of
    Ok res ->
      case res of
        Ok data -> okFunc data
        Err err -> errFunc err
    Err err -> errFunc (errToStr err)


--
-- Private types
--

type alias GraphQl a =
  { data : GraphQlData a
  , errors : List GraphQlError
  }

type alias GraphQlData a =
  { sub : a }


type alias GraphQlError =
  { message : String }


type alias ApiError =
  { message : String }


type alias ApiErrors =
  { errors: List ApiError }


type alias ApiExtError =
  { success : Bool
  , message: String }


--
-- Decoders
--

graphqlDecoder : String -> Decoder a -> Decoder (Response a)
graphqlDecoder name dec =
  decode GraphQl
    |> required "data" (graphqlDataDecoder name dec)
    |> optional "errors" (Decode.list graphqlError) []


graphqlDataDecoder : String -> Decoder a -> Decoder (GraphQlData (Maybe a))
graphqlDataDecoder name dec =
  decode GraphQlData
    |> required name (Decode.nullable dec)


graphqlError : Decoder GraphQlError
graphqlError = decode GraphQlError |> required "message" Decode.string


apiErrorsDecoder : Decode.Decoder ApiErrors
apiErrorsDecoder =
  decode ApiErrors
    |> required "errors" (Decode.list apiErrorDecoder)


apiErrorDecoder :  Decode.Decoder ApiError
apiErrorDecoder =
  decode ApiError
    |> required "message" Decode.string


apiExtErrorDecoder :  Decode.Decoder ApiExtError
apiExtErrorDecoder =
  decode ApiExtError
    |> required "success" Decode.bool
    |> required "message" Decode.string


-- Body for the GraphQL requests.
body : String -> Value -> Http.Body
body query variables =
  Http.jsonBody
    <| object
      [ ("query", string query)
      , ("variables", variables)
      ]


-- Parse all the possible errors.
errToStr : Http.Error -> String
errToStr e =
  case e of
    Http.BadUrl s -> s
    Http.Timeout -> "Timeout: server is too long to get the responses"
    Http.NetworkError -> "Network error"
    Http.BadStatus rep ->
      case Decode.decodeString apiErrorsDecoder rep.body of
              (Err e)   ->
                case Decode.decodeString apiExtErrorDecoder rep.body of
                  (Err _) -> "HTTP error: " ++ rep.body
                  (Ok err) -> err.message
              (Ok err) -> String.join ", " (List.map (.message) err.errors)
    Http.BadPayload err rep ->
      case Decode.decodeString apiErrorsDecoder rep.body of
              (Err e)   -> "GraphQL API error: " ++ rep.body
              (Ok err) -> String.join ", " (List.map (.message) err.errors)
