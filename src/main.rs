use std::sync::Arc;

use axum::{extract::{State, Json}, routing::{post, get}, Router, http::StatusCode};
use jammdb::{Data, Error, Tx, DB};
use serde::Deserialize;
use url::{Url, ParseError};

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    // build our application with a single route
    let database = Arc::new(DB::open("database.db").unwrap());
    let app = Router::new()
        .route("/create_link", post(create_link))
        .route("/get_link", get(get_link))
        .with_state(database);
    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[derive(Deserialize)]
struct CreateLink {
    link: Url,
    preffered_url: Option<String>
}

async fn create_link(State(state): State<Arc<DB>>, link: Json<CreateLink>) ->  (StatusCode, String) {
    let url = match link.preffered_url.clone() {
        Some(url) => url,
        None => String::from("generatenew")
    };
    let original = link.link.to_string();
    let mut tx = state.tx(true).unwrap();
    match tx.get_bucket("links") {
        Ok(bucket) => {bucket.put(url, original.clone()).unwrap();},
        Err(Error::BucketMissing) => {
            tx.create_bucket("links").unwrap().put(url, original.clone()).unwrap();
        },
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, String::from("Server Error"))
    };
    tx.commit().unwrap();
    (StatusCode::CREATED, original.clone())
}

async fn get_link(State(state): State<Arc<DB>>, link: String) ->  (StatusCode, String) { 
    let mut tx = state.tx(true).unwrap();
    let value = match tx.get_bucket("links") {
        Ok(bucket) => bucket.get(link).unwrap(),
        Err(_) => panic!("Unrecoverable")
    };
    let string = match String::from_utf8(value.kv().value().to_vec()) {
        Ok(x) => x,
        Err(e) => return interal_server_error(e)
    };
    tx.commit().unwrap();
    (StatusCode::OK, String::from(string))
}

fn interal_server_error(thing: impl std::error::Error) -> (StatusCode, String) {
    (StatusCode::INTERNAL_SERVER_ERROR, format!("Server Error: {}", thing.to_string()))

}
