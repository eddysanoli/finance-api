use axum::{Json, Router, response::IntoResponse, routing::get};
use log;
use serde_json;
use env_logger;

#[tokio::main]
async fn main() {
    env_logger::init();
    log::info!("Configured logger");

    // Setup the router and start the server
    let addr = "127.0.0.1:3000";
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    println!("Listening on http://{}", addr);
    axum::serve(listener, router()).await.unwrap();
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
