module Api exposing (users, userById, addUser, editUser)

{- Example to use the tiny API defined in server.js.

-}

import Http
import Json.Encode as Encode
import User exposing (User, Users, UserInput)
import GraphQL as QL


config : String -> QL.Config
config token =
  QL.Config [ ("authorization", token) ] "/api/graphql"


--
-- Get all users.
--

users : String -> (QL.Purpose Users -> msg) -> Cmd msg
users token resultCallback =
  QL.cmd (reqUsers token) resultCallback


reqUsers : String -> Http.Request (QL.Response Users)
reqUsers token =
  QL.exec (config token) "users"
    |> QL.query queryUsers
    |> QL.variables Encode.null
    |> QL.decoder User.usersDecoder


queryUsers : String
queryUsers =
  """
  query {
    users { id login firstname lastname email }
  }
  """


--
-- Get a user by id.
--

userById : String -> Int -> (QL.Purpose User -> msg) -> Cmd msg
userById token id resultCallback =
  QL.cmd (reqUserById token id) resultCallback


reqUserById : String -> Int -> Http.Request (QL.Response User)
reqUserById token id =
  QL.exec (config token) "userById"
    |> QL.query queryUserById
    |> QL.variables (Encode.object [ ("id",  Encode.int id)])
    |> QL.decoder User.userDecoder


queryUserById : String
queryUserById =
  """
  query UserById($id: Int!) {
    userById(id: $id) { id login firstname lastname email }
  }
  """


--
-- Add a new user
--

addUser : String -> UserInput -> (QL.Purpose User -> msg) -> Cmd msg
addUser token user resultCallback =
  QL.cmd (reqAddUser token user) resultCallback


reqAddUser : String -> UserInput -> Http.Request (QL.Response User)
reqAddUser token user =
  QL.exec (config token) "addUser"
    |> QL.query queryAddUser
    |> QL.variables (Encode.object [ ("user",  User.encodeUserInput user)])
    |> QL.decoder User.userDecoder


queryAddUser : String
queryAddUser =
  """
  mutation AddUser($user: UserIn!) {
    addUser(user: $user) {
      id login firstname lastname
    }
  }
  """


--
-- Edit an existing user
--

editUser : String -> Int -> UserInput -> (QL.Purpose User -> msg) -> Cmd msg
editUser token id user resultCallback =
  QL.cmd (reqEditUser token id user) resultCallback


reqEditUser : String -> Int -> UserInput -> Http.Request (QL.Response User)
reqEditUser token id user =
  QL.exec (config token) "editUser"
    |> QL.query queryEditUser
    |> QL.variables (Encode.object
      [ ("id", Encode.int id)
      , ("user",  User.encodeUserInput user) ] )
    |> QL.decoder User.userDecoder


queryEditUser : String
queryEditUser =
  """
  mutation EditUser($id: Int!, $user: UserInput!) {
    editUser(id: $id, user: $user) {
      id login firstname lastname
    }
  }
  """
