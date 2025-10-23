use axum::{Json, Router, response::IntoResponse, routing::get};
use dotenv::dotenv;
use env_logger;
use log;
use serde_json;
use sqlx::postgres::PgPoolOptions;
use std::env;

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    env_logger::init();
    log::info!("Configured logger");

    // ============ ENVIRONMENT VARIABLES ============

    dotenv().ok();
    let db_user = env::var("DB_USER").unwrap_or("postgres".to_string());
    let db_pass = env::var("DB_PASSWORD").unwrap_or("password".to_string());
    let db_name = env::var("DB_NAME").unwrap_or("database".to_string());
    let db_host = env::var("DB_HOST").unwrap_or("localhost".to_string());
    let db_port = env::var("DB_PORT").unwrap_or("5432".to_string());

    // =============== SQL CONNECTION ================

    let database_url = format!(
        "postgres://{}:{}@{}:{}/{}",
        db_user, db_pass, db_host, db_port, db_name
    );
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;
    let row: (i64,) = sqlx::query_as("SELECT $1")
        .bind(150_i64)
        .fetch_one(&pool)
        .await?;

    println!("Got: {:?}", row.0);
    log::info!(target: "main", "Connected to the database");

    // =================== ROUTER ====================

    // Setup the router and start the server
    let addr = "127.0.0.1:3000";
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    log::info!(target: "main", "Listening on http://{}", addr);
    axum::serve(listener, router()).await.unwrap();

    Ok(())
}

fn router() -> Router {
    Router::new().route("/api/v1/healthcheck", get(health_check_handler))
}

async fn health_check_handler() -> impl IntoResponse {
    log::info!(target: "healthcheck", "Health check endpoint called");
    let json_response = serde_json::json!({
        "status": "ok",
        "message": "Service is running"
    });
    return Json(json_response);
}
