default: check test build

check:
    pre-commit run --all-files

test:
    gleam test

build:
    gleam build
    gleam export erlang-shipment
