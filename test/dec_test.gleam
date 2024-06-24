import dec
import gleam/dict
import gleam/dynamic
import gleam/io
// import gleeunit/should

pub type User {
  User(name: String, age: Int, height: Float, account: Account)
}

pub type Account {
  Account(id: Int, provider: String)
}

pub fn account_decoder() {
  use id <- dec.parameter("id", dec.int())
  use provider <- dec.parameter("provider", dec.string())
  dec.decoded(Account(id, provider))
}

pub fn user_decoder() {
  use name <- dec.parameter("name", dec.string())
  use age <- dec.parameter("age", dec.int())
  use height <- dec.parameter("height", dec.float())
  use account <- dec.parameter("account", account_decoder())
  dec.decoded(User(name, age, height, account))
}

pub fn dec_user_test() {
  let data: dynamic.Dynamic =
    dict.from_list([
      #("name", dynamic.from("Alice")),
      #("age", dynamic.from(30)),
      #("height", dynamic.from(1.7)),
      #("account", dynamic.from(dict.from_list([
        #("id", dynamic.from(1)),
        #("provider", dynamic.from("google"))
      ])))
    ])
    |> dynamic.from

  let user = user_decoder() |> dec.decode(data)

  io.debug(user)
}
