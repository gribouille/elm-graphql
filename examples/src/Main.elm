module Main exposing (main)

import Browser
import Html exposing (..)
import GraphQL
import User exposing (User, usersDecoder)
import Http

queryUsers : String
queryUsers =
  """
  query {
    users { id login firstname lastname email }
  }
  """

type alias Model = List User

type Msg =
  OnUsers (GraphQL.Response (List User))

main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }


init : () -> (Model, Cmd Msg)
init _ =
  ( []
  , GraphQL.run
    { query = queryUsers
    , headers = []
    , url = "http://localhost:4000/graphql"
    , root = "users"
    , decoder = usersDecoder
    , on = OnUsers
    , variables = Nothing
    }
  )


view : Model -> Html Msg
view users =
  ul [] <| List.map (\user ->
    li [] [ text (user.firstname ++ " " ++ user.lastname ++ " (" ++ user.login ++ ")") ]
  ) users


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    OnUsers res ->
      case GraphQL.segment res of
        GraphQL.ResHttpError err ->
          let
            _ = Debug.log "ResHttpError" err
          in
            (model, Cmd.none)
        GraphQL.ResOnlyErrors errs ->
          let
            _ = Debug.log "ResOnlyErrors" errs
          in
            (model, Cmd.none)
        GraphQL.ResWithErrors errs users ->
          let
            _ = Debug.log "ResWithErrors" errs
          in
            (users, Cmd.none)
        GraphQL.ResWithoutError users ->
          (users, Cmd.none)