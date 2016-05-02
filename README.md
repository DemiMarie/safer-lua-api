# safer-lua-api

This repository includes a shim library that makes binding to the Lua API much safer.

It catches all Lua errors and returns them as error codes.

## Prerequisites

You will need a C or C++ compiler that supports thread-local storage.
Recent versions of GCC and Clang meet the requirements.

## License

This software is dual-licensed under the [MIT license][1] and the [Apache License, version 2.0][2].
By submitting to this repository, you agree to license your code under this dual license,
with no further terms and conditions.

[1]: LICENSE
[2]: LICENSE-APACHE
