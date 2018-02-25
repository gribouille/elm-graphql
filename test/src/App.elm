module App exposing (..)

{- This very basic example is only to show how to use the gribouille/elm-graphql
library.
-}

import Html as H
import Html.Events as HE
import Html.Attributes as HA

import GraphQL
import Api
import User exposing (User, Users, UserInput, usersDecoder, encodeUserInput)


--
-- Model
--

type alias Model =
  { error: Maybe String     -- to show the errors messages
  , success: Maybe String   -- to show the success messages
  , users: Users            -- list of users
  , fieldId : Int           -- for the input field id
  , fieldUser : UserInput   -- for the other input fields
  }


init : (Model, Cmd Msg)
init =
  (Model Nothing Nothing [] -1 (UserInput "" "" "" "")) ! []


--
-- Messages
--

type Msg
  = OnGetUsers (GraphQL.Purpose Users)    -- reponse from `users`
  | OnUserById (GraphQL.Purpose User)     -- reponse from `userById`
  | OnEditUser (GraphQL.Purpose User)     -- reponse from `editUser`
  | OnAddUser (GraphQL.Purpose User)      -- reponse from `addUser`
  | Click Request                         -- messages for the buttons
  | Set Field String                      -- messages for the form inputs


type Request
  = GetUsers
  | GetUserById
  | EditUser
  | AddUser


type Field
  = Id
  | Login
  | Firstname
  | Lastname
  | Email


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Click req ->
      let
        cmd = case req of
          -- this request is always success
          GetUsers    -> Api.users    "valid_token" OnGetUsers
          -- this request fails if the id is invalid (first error type: GraphQL error)
          EditUser    -> Api.editUser "valid_token" model.fieldId model.fieldUser OnEditUser
          -- this request always fails because the token is invalid (second error type: not a GraphQL error)
          AddUser     -> Api.addUser  "invalid_token" model.fieldUser OnAddUser
          -- Not used in this example
          GetUserById -> Api.userById "valid_token" model.fieldId OnUserById
      in
        { model | error = Nothing, success = Nothing } ! [ cmd ]
    -- examples to set the model in function of the GraphQL response
    OnGetUsers res -> GraphQL.response model res
      (\users -> { model | users = users, success = Just "get all users" } ! [] )
      (\error -> { model | error = Just error } ! [] )
    OnAddUser res -> GraphQL.response model res
      (\user -> { model | success = Just ("user " ++ user.login ++ " added!") } ! [] )
      (\error -> { model | error = Just error } ! [] )
    OnEditUser res -> GraphQL.response model res
      (\user -> { model | success = Just ("user " ++ user.login ++ " edited!") } ! [] )
      (\error -> { model | error = Just error } ! [] )
    -- TODO: not used in this example
    OnUserById res -> model ! []
    Set field value -> (setField model field value) ! []


setField : Model -> Field -> String -> Model
setField model field value =
  let
    fu = model.fieldUser
  in
    case field of
      Id -> { model | fieldId = Result.withDefault -1 (String.toInt value) }
      Login -> { model | fieldUser = { fu | login = value } }
      Firstname -> { model | fieldUser = { fu | firstname = value } }
      Lastname -> { model | fieldUser = { fu | lastname = value } }
      Email -> { model | fieldUser = { fu | email = value } }


--
-- View
--

view : Model -> H.Html Msg
view model =
  H.div []
  [ H.h1 [] [ H.text "gribouille/elm-graphql example" ]
  , viewStatus "error" "Error: " model.error
  , viewStatus "success" "Success: " model.success
  , H.div [ HA.class "panel" ]
    [ H.span [] [ H.text "Valid request (refresh all data): " ]
    , H.button [ HA.class "btn green", HE.onClick (Click GetUsers) ] [ H.text "↻" ]
    , H.div []
      [ H.table []
        [ H.thead []
          [ H.tr []
            [ H.th [] [ H.text "id" ]
            , H.th [] [ H.text "login" ]
            , H.th [] [ H.text "firstname" ]
            , H.th [] [ H.text "lastname" ]
            , H.th [] [ H.text "email" ]
            ]
          ]
        , H.tbody [] <| List.map (\user -> H.tr []
            [ H.td [] [ H.text (toString user.id) ]
            , H.td [] [ H.text user.login ]
            , H.td [] [ H.text user.firstname ]
            , H.td [] [ H.text user.lastname ]
            , H.td [] [ H.text user.email ]
            ]) model.users
        ]
      ]
    ]
  , H.div [ HA.class "panel" ]
    [ H.span [] [ H.text "GraphQL error if invalid id (edit exising user): " ]
    , H.button [ HA.class "btn orange", HE.onClick (Click EditUser) ] [ H.text "✎" ]
    , H.div [] [ H.input [ HA.class "field", HA.type_ "text", HA.placeholder "Id", HE.onInput (Set Id) ] [] ]
    , H.div [] [ H.input [ HA.class "field", HA.type_ "text", HA.placeholder "Login", HE.onInput (Set Login) ] [] ]
    , H.div [] [ H.input [ HA.class "field", HA.type_ "text", HA.placeholder "Firstname", HE.onInput (Set Firstname) ] [] ]
    , H.div [] [ H.input [ HA.class "field", HA.type_ "text", HA.placeholder "Lastname", HE.onInput (Set Lastname) ] [] ]
    , H.div [] [ H.input [ HA.class "field", HA.type_ "text", HA.placeholder "Email", HE.onInput (Set Email) ] [] ]
    ]
  , H.div [ HA.class "panel" ]
    [ H.span [] [ H.text "Invalid request (error in token): " ]
    , H.button [ HA.class "btn red", HE.onClick (Click AddUser) ] [ H.text "✗" ]
    ]
  ]


viewStatus : String -> String -> Maybe String -> H.Html msg
viewStatus class title field =
  Maybe.map (\msg -> H.div [ HA.class <| "panel " ++ class ]
    [ H.strong [] [ H.text title ]
    , H.span [] [ H.text msg ]
    ]) field
  |> Maybe.withDefault (H.text "")


--
-- Entry point
--

main : Program Never Model Msg
main =
  H.program
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }
