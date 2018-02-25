# elm-graphql

A ELM library to use the GraphQL API.

To install the library:

```
> elm-package install gribouille/elm-graphql
```


## Example

1) Configure the API. In this example, the API is protected with a JSON web token
in the `authorization` header:
```elm
config : String -> GraphQL.Config
config token =
  GraphQL.Config [ ("authorization", "Bearer " ++ token) ] "/api/graphql"
```

2) Create a GraphQL request with `cmd` and `exec`:
```elm
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
```

3) Get the results in the `update` function:
```elm
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
```


## Documentation

The API documentation is available [here](http://package.elm-lang.org/packages/gribouille/elm-graphql/latest).


## Usage

To run the examples:

```shell
$ cd test
$ npm install
$ npm run server
$ npm run dev
```
Open [localhost:8080](http://localhost:8080).


## Contributing

Feedback and contributions are very welcome.


## License

This project is licensed under [Mozilla Public License Version 2.0](./LICENSE).
