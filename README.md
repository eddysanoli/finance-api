# Finance API

Personal finance API built with Rust, with the goal of speeding up my ability to track and analyze my expenses. Eventually it will be connected with a separate frontend and discord bot to speed up things.

## Useful Commands

### Rust API

- Build: `cargo build`
- Run: `cargo run`
- Check for compilation errors: `cargo check`
- Watch for changes and recompile: `bacon`. Press `r` to run the repo after starting

### Database

- Remote into test container: `docker exec -it finance-api-db bin/sh`
- Connect to database: `psql TEST_DB_NAME -U TEST_DB_USER`
- Clean database: `docker volume rm -f finance-api_db_data`
