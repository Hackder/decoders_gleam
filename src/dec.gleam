import gleam/dynamic.{type Dynamic, field}
import gleam/list


type Decoder(a) =
  fn() -> #(fn() -> a, fn(Dynamic) -> Result(a, dynamic.DecodeErrors))

pub fn parameter(
  name: String,
  decoder: Decoder(a),
  next: fn(a) -> Decoder(b),
) -> Decoder(b) {
  let default_fn = fn() {
    let #(default, _) = decoder()
    next(default())().0()
  }

  let decoder_fn = fn(data) {
    let #(default, decoder) = decoder()

    let merge_errors = fn(errors) {
      let #(_, decode) = next(default())()
      case decode(data) {
        Ok(_) -> Error(errors)
        Error(next_errors) -> Error(errors |> list.append(next_errors))
      }
    }

    case dynamic.field(name, dynamic.dynamic)(data) {
      Ok(maybe_value) -> case decoder(maybe_value) {
        Ok(value) -> next(value)().1(data)
        Error(errors) -> merge_errors(errors)
      }
      Error(errors) -> Error(errors)
    }
  }

  fn() { #(default_fn, decoder_fn) }
}

pub fn decoded(a) {
  let default_fn = fn() { a }
  let decoder_fn = fn(_) { Ok(a) }
  fn() { #(default_fn, decoder_fn) }
}

fn from_dynamic_decoder(
  decoder: fn(Dynamic) -> Result(a, dynamic.DecodeErrors),
  default: a,
) -> Decoder(a) {
  let default = fn() { default }

  fn() { #(default, decoder) }
}


pub fn string() {
  from_dynamic_decoder(dynamic.string, "")
}

pub fn int() {
  from_dynamic_decoder(dynamic.int, 0)
}

pub fn float() {
  from_dynamic_decoder(dynamic.float, 0.0)
}

pub fn decode(decoder: Decoder(a), data: Dynamic) -> Result(a, dynamic.DecodeErrors) {
  let #(_, decode) = decoder()
  decode(data)
}
