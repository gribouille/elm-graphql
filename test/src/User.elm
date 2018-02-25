module User exposing (..)

import Json.Encode as E
import Json.Decode as D
import Json.Decode.Pipeline exposing (decode, required, optional)


type alias User =
  { id        : Int
  , login     : String
  , firstname : String
  , lastname  : String
  , email     : String
  }


type alias Users = List User


type alias UserInput =
  { login     : String
  , firstname : String
  , lastname  : String
  , email     : String
  }

userDecoder : D.Decoder User
userDecoder =
  decode User
    |> required "id"        D.int
    |> required "login"     D.string
    |> optional "firstname" D.string ""
    |> optional "lastname"  D.string ""
    |> optional "email"     D.string ""


usersDecoder : D.Decoder Users
usersDecoder = D.list userDecoder


encodeUserInput : UserInput -> E.Value
encodeUserInput v =
  E.object
  [ ("login"    , E.string v.login)
  , ("firstname", E.string v.firstname)
  , ("lastname" , E.string v.lastname)
  , ("email"    , E.string v.email)
  ]
