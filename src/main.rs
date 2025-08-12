use axum::{routing::get, Router);

#[tokio::main]
async fn main() {
    let addr = "127.0.0.1:3000";
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    println!("Listening on http://{}", addr);
    axum::serve(listener, router()).await.unwrap();
}

fn router() -> Router {
    Router::new().route("/", get(hello_world))
}

async fn hello_world() -> &'static str {
    "Hello, World!"
}
