import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/io
import gleam/list

pub type User {
  User(name: String, age: Int, height: Float)
}

// Original

pub fn decode_user(json: Dynamic) -> Result(User, List(dynamic.DecodeError)) {
  json
  |> dynamic.decode3(
    User,
    dynamic.field("name", dynamic.string),
    dynamic.field("age", dynamic.int),
    dynamic.field("height", dynamic.float),
  )
}

// First try

pub fn decode_user_first_try(
  json: Dynamic,
) -> Result(User, List(dynamic.DecodeError)) {
  use name <- parameter1(json, "name", dynamic.string)
  use age <- parameter1(json, "age", dynamic.int)
  use height <- parameter1(json, "height", dynamic.float)
  Ok(User(name, age, height))
}

pub fn parameter1(
  data: Dynamic,
  key: String,
  decoder: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
  next: fn(a) -> Result(b, List(dynamic.DecodeError)),
) -> Result(b, List(dynamic.DecodeError)) {
  case dynamic.field(key, decoder)(data) {
    Ok(value) -> next(value)
    Error(error) -> Error(error)
  }
}

// Second try

pub fn decode_user_second_try(
  json: Dynamic,
) -> Result(User, List(dynamic.DecodeError)) {
  {
    use name <- parameter2("name", dynamic.string)
    use age <- parameter2("age", dynamic.int)
    use height <- parameter2("height", dynamic.float)
    Value(User(name, age, height))
  }
  |> decode(json)
}

pub fn parameter2(
  key: String,
  decoder: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
  next: fn(a) -> PartialDecode(b),
) -> PartialDecode(b) {
  Next(fn(data: Dynamic) {
    case dynamic.field(key, decoder)(data) {
      Ok(value) -> next(value)
      Error(error) -> Err(error)
    }
  })
}

pub type PartialDecode(a) {
  Value(a)
  Err(List(dynamic.DecodeError))
  Next(fn(Dynamic) -> PartialDecode(a))
}

pub fn decode(
  partial: PartialDecode(a),
  data: Dynamic,
) -> Result(a, List(dynamic.DecodeError)) {
  case partial {
    Value(value) -> Ok(value)
    Err(errors) -> Error(errors)
    Next(next) -> decode(next(data), data)
  }
}

// ---------------------------------
// Returns all errors
// --------------------------------

// First try

pub fn decode_user_all_first_try(
  json: Dynamic,
) -> Result(User, List(dynamic.DecodeError)) {
  use name <- parameter_all1(json, "name", dyn_string)
  use age <- parameter_all1(json, "age", dyn_int)
  use height <- parameter_all1(json, "height", dyn_float)
  Ok(User(name, age, height))
}

pub fn parameter_all1(
  data: Dynamic,
  key: String,
  decoder: #(a, Decoder(a)),
  next: fn(a) -> Result(b, List(dynamic.DecodeError)),
) -> Result(b, List(dynamic.DecodeError)) {
  let #(default, decoder) = decoder

  let merge_errors = fn(errors) {
    list.append(errors, case next(default) {
      Ok(_) -> []
      Error(errors) -> errors
    })
    |> Error
  }

  case dynamic.field(key, dynamic.dynamic)(data) {
    Ok(value) ->
      case decoder(value) {
        Ok(value) -> next(value)
        Error(errors) -> merge_errors(errors)
      }
    Error(errors) -> merge_errors(errors)
  }
}

type Decoder(a) =
  fn(Dynamic) -> Result(a, List(dynamic.DecodeError))

const dyn_string = #("", dynamic.string)

const dyn_int = #(0, dynamic.int)

const dyn_float = #(0.0, dynamic.float)

// Second try

pub fn decode_user_all_second_try(
  json: Dynamic,
) -> Result(User, List(dynamic.DecodeError)) {
  json
  |> {
    use name <- parameter_all2("name", dyn_string)
    use age <- parameter_all2("age", dyn_int)
    use height <- parameter_all2("height", dyn_float)
    fn(_) { Ok(User(name, age, height)) }
  }
}

pub fn parameter_all2(
  key: String,
  decoder: #(a, Decoder(a)),
  next: fn(a) -> fn(Dynamic) -> Result(b, List(dynamic.DecodeError)),
) -> fn(Dynamic) -> Result(b, List(dynamic.DecodeError)) {
  let #(default, decoder) = decoder

  fn(data: Dynamic) {
    let merge_errors = fn(errors) {
      list.append(errors, case next(default)(data) {
        Ok(_) -> []
        Error(errors) -> errors
      })
      |> Error
    }

    case dynamic.field(key, dynamic.dynamic)(data) {
      Ok(value) ->
        case decoder(value) {
          Ok(value) -> next(value)(data)
          Error(errors) -> merge_errors(errors)
        }
      Error(errors) -> merge_errors(errors)
    }
  }
}

pub fn main() {
  let json =
    dict.from_list([
      #("name", dynamic.from("Alice")),
      #("age", dynamic.from(34)),
      #("height", dynamic.from(180.0)),
    ])
    |> dynamic.from

  // let assert Ok(user) = decode_user_first_try(json)
  // io.debug(user)
  // let assert Ok(user) = decode_user_second_try(json)
  // io.debug(user)
  //
  // let assert Ok(user) = decode_user_all_first_try(json)
  // io.debug(user)
  let assert Ok(user) = decode_user_all_second_try(json)
  io.debug(user)
}
