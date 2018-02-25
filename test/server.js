'use strict'

const express     = require('express')
const bodyParser  = require('body-parser')
const graphqlHTTP = require('express-graphql')
const graphql     = require('graphql')

const port        = process.env.PORT || 4000
const schema      = `
type User {
  id: Int!
  login: String!
  firstname: String
  lastname: String
  email: String
}

input UserInput {
  login: String!
  firstname: String
  lastname: String
  email: String
}

type Query {
  users: [User!]!
  userById(id: Int!): User
}

type Mutation {
  addUser(user: UserInput!): User
  editUser(id: Int!, user: UserInput!): User
}
`

class User {
  constructor(id, login, firstname, lastname, email) {
    this.id = id
    this.login = login
    this.firstname = firstname
    this.lastname = lastname
    this.email = email
  }
}

const users =
  [ new User(1, 'bleponge', 'Bob', 'Leponge', 'bob.leponge@corp.com')
  , new User(2, 'ctentatcule', 'Carlo', 'Tentacule', 'carlo.tentacule@corp.com')
  , new User(3, 'splankton', 'Sheldon', 'Plankton', 'sheldon.plankton@corp.com')
  , new User(4, 'secureuil', 'Sandy', 'Ecureuil', 'sandy.ecureuil@corp.com')
  ]

const root      = {
  users: () => { return users },
  userById: ({id}) => { return users.find(x => x.id === id) },
  addUser: ({user}) => {
    const id = users.length + 1
    const u = new User(id, user.login, user.firstname, user.lastname, user.email)
    users.push(u)
    return u
  },
  editUser: ({id, user}) => {
    const u = users.find(x => x.id === id)
    if (u === undefined) {
      throw new Error(`user with the id ${id} not found!`)
    }
    u.login = user.login
    u.firstname = user.firstname
    u.lastname = user.lastname
    u.email = user.email
    return u
  },
}

const app         = express()
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())
app.use((req, res, next) => {
  const token = req.headers['authorization']
  if (token !== 'valid_token') {
    res.status(500).json({message: 'invalid token'})
    return
  }
  next()
})
app.use('/graphql', graphqlHTTP(
  req => ({
    schema: graphql.buildSchema(schema)
    , rootValue: root
    , graphiql: true
    , context: req
    , formatError: error => (
      { message: error.message
      , locations: error.locations
      , stack: error.stack
      , path: error.path
      }
    )
  })
))

console.log(`Start server on :${port}`)
app.listen(port)
