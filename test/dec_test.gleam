//// Pros:
//// - The decoder is defined in a single place
//// - The decoder is composable
//// - A single property is on a single line. When editing, you edit only
////   a single line. No need to modify the decoder in multiple places.
//// Cons:
//// - The presence of default values may cause issues if any side effects
////   are present in the decoder function.
//// - Perf. Decoders are probably gonna be ran a lot, so they should be fast.
////   (This is not the fastest)
//// Ideas:
//// - Use custom decoders and errors with the ability to add validation

import dec
import gleam/dict
import gleam/dynamic
import gleeunit/should

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
      #(
        "account",
        dynamic.from(
          dict.from_list([
            #("id", dynamic.from(1)),
            #("provider", dynamic.from("google")),
          ]),
        ),
      ),
    ])
    |> dynamic.from

  user_decoder()
  |> dec.decode(data)
  |> should.equal(Ok(User("Alice", 30, 1.7, Account(1, "google"))))
}

pub fn first_level_error_test() {
  let data: dynamic.Dynamic =
    dict.from_list([
      #("name", dynamic.from("Alice")),
      #("age", dynamic.from(30)),
      #("height", dynamic.from("hiii")),
      #(
        "account",
        dynamic.from(
          dict.from_list([
            #("id", dynamic.from(1)),
            #("provider", dynamic.from("google")),
          ]),
        ),
      ),
    ])
    |> dynamic.from

  user_decoder()
  |> dec.decode(data)
  |> should.equal(Error([dynamic.DecodeError("Float", "String", ["height"])]))
}

pub fn second_level_error_test() {
  let data: dynamic.Dynamic =
    dict.from_list([
      #("name", dynamic.from("Alice")),
      #("age", dynamic.from(30)),
      #("height", dynamic.from(1.7)),
      #(
        "account",
        dynamic.from(
          dict.from_list([
            #("id", dynamic.from("1")),
            #("provider", dynamic.from("google")),
          ]),
        ),
      ),
    ])
    |> dynamic.from

  user_decoder()
  |> dec.decode(data)
  |> should.equal(
    Error([dynamic.DecodeError("Int", "String", ["account", "id"])]),
  )
}

pub fn multiple_errors_test() {
  let data: dynamic.Dynamic =
    dict.from_list([
      #("name", dynamic.from("Alice")),
      #("age", dynamic.from("")),
      #("height", dynamic.from("")),
      #(
        "account",
        dynamic.from(
          dict.from_list([
            #("id", dynamic.from("1")),
            #("provider", dynamic.from("google")),
          ]),
        ),
      ),
    ])
    |> dynamic.from

  user_decoder()
  |> dec.decode(data)
  |> should.equal(
    Error([
      dynamic.DecodeError("Int", "String", ["age"]),
      dynamic.DecodeError("Float", "String", ["height"]),
      dynamic.DecodeError("Int", "String", ["account", "id"]),
    ]),
  )
}
