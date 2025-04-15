use std::sync::Arc;

use axum::{
    extract::{Json, State},
    http::{Method, StatusCode},
    routing::post,
    Router,
};
use jammdb::DB;
use serde::Deserialize;
use tower_http::cors::{Any, CorsLayer};
use url::Url;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    // build our application with a single route
    let database = Arc::new(DB::open("database.db").unwrap());
    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST])
        .allow_headers(Any)
        .allow_origin(Any);
    let app = Router::new()
        .route("/create_link", post(create_link))
        .route("/get_link", post(get_link))
        .with_state(database)
        .layer(cors);
    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[derive(Deserialize)]
struct CreateLink {
    link: Url,
    preffered_url: Option<String>,
}

async fn create_link(State(state): State<Arc<DB>>, link: Json<CreateLink>) -> (StatusCode, String) {
    let url = match &link.preffered_url {
        Some(url) => url.clone(),
        None => random_word::gen_len(3, random_word::Lang::En).unwrap().to_owned(),
    };
    let original = link.link.to_string();
    let tx = state.tx(true).unwrap();
    match tx.get_or_create_bucket("links") {
        Ok(bucket) => {
            if bucket.get(&url).is_some() {
                if let Some(pu) = &link.preffered_url {
                    return (
                        StatusCode::CONFLICT,
                        format!("Extension {pu} is already taken"),
                    );
                }
            }
            bucket.put(url.clone(), original).unwrap();
        }
        Err(e) => return internal_server_error(e),
    }
    tx.commit().unwrap();
    (StatusCode::CREATED, url)
}

async fn get_link(State(state): State<Arc<DB>>, link: String) -> (StatusCode, String) {
    let tx = state.tx(true).unwrap();
    let value = match tx.get_or_create_bucket("links") {
        Ok(bucket) => match bucket.get(&link) {
            Some(x) => x,
            None => return (StatusCode::NOT_FOUND, String::from("No link")),
        },
        Err(e) => return internal_server_error(e),
    };
    let string = match String::from_utf8(value.kv().value().to_vec()) {
        Ok(x) => x,
        Err(e) => return internal_server_error(e),
    };
    tx.commit().unwrap();
    (StatusCode::OK, String::from(string))
}

fn internal_server_error(thing: impl std::error::Error) -> (StatusCode, String) {
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        format!("Server Error: {}", thing.to_string()),
    )
}
