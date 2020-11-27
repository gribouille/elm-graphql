# elm-graphql

A simple ELM library to use the GraphQL API.


## Install

```
> elm install gribouille/elm-graphql
```


## Examples

To run the examples:

```shell
$ cd examples
$ npm install
$ npm run server
$ npm run dev
```
Open [http://localhost:8000/src/Main.elm](http://localhost:8000/src/Main.elm).


## Usage

GraphQL API:

```graphql
type User {
  id: Int!
  login: String!
  firstname: String
  lastname: String
  email: String
}

type Query {
  users: [User!]!
  ...
}
```

Library usage:

```elm
type alias User =
  { id        : Int
  , login     : String
  , firstname : String
  , lastname  : String
  , email     : String
  }


userDecoder : Decoder User
userDecoder = ...


type Msg
  = OnUsers (GraphQL.Response (List User))
  | ...


get : Cmd Msg
get =
  GraphQL.run
  { query = "query { users { id login firstname lastname email } }"
  , decoder = usersDecoder
  , root = "users"
  , url = "<url/graphql>"
  , headers = []
  , on = OnUsers
  , variables = Nothing
  }
```


## Documentation

The API documentation is available [here](http://package.elm-lang.org/packages/gribouille/elm-graphql/latest).




## Contributing

Feedback and contributions are very welcome.


## License

This project is licensed under [Mozilla Public License Version 2.0](./LICENSE).
