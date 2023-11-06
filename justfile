dev-env +args:
    docker compose --env-file dev.env -f dev.docker-compose.yml {{args}}

setup:
    mix deps.get
    (cd examples/echo_bot && mix deps.get)

run-echo-bot:
    (cd examples/echo_bot \
        && rm -rf _build/dev/lib/plug \
        && iex -S mix)

cd-format path='':
    (cd {{path}} && mix format)

format:
    mix format
    just cd-format examples/echo_bot
