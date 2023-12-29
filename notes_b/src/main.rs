use axum::{
    extract::{Path, Request, State},
    http::{HeaderMap, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::{get, patch, post},
    Extension, Json, Router,
};

use bcrypt::{hash, verify};
use chrono::Utc;
use dotenvy::dotenv;
use dotenvy_macro::dotenv;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use sqlx::types::chrono;
use sqlx::Row;

//-------- request
#[derive(Debug, Deserialize, Serialize)]
struct NoteRequest {
    title: String,
    description: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct UpdateNoteRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    title: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
struct UserRequest {
    email: String,
}

//-------- response
#[derive(Debug, Deserialize, Serialize)]
struct NotesResponse {
    notes: Vec<NoteResponse>,
}

#[derive(Debug, Deserialize, Serialize)]
struct NoteResponse {
    id: String,
    uid: String,
    created_at: chrono::DateTime<chrono::Utc>,
    title: String,
    description: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct ApiKeyResponse {
    id: String,
    name: String,
    scope: Vec<String>,
    api_key: String,
    prefix: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct ApiKeysResponse {
    id: String,
    name: String,
    scope: Vec<String>,
    prefix: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct ApiKeysListResponse {
    data: Vec<ApiKeysResponse>,
}

#[derive(Debug, Deserialize, Serialize)]
struct ApiKeyMiddlewareResponse {
    id: String,
    name: String,
    uid: String,
    scope: Vec<String>,
    api_key: String,
    prefix: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct ApiMiddlewareResponse {
    uid: String,
    scope: Vec<String>,
}

//--------error ---
#[derive(Debug)]
struct AppError {
    code: StatusCode,
    message: String,
}

#[derive(Serialize)]
struct ResponseMessage {
    error: String,
}

impl AppError {
    pub fn new(code: StatusCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        (
            self.code,
            Json(ResponseMessage {
                error: self.message,
            }),
        )
            .into_response()
    }
}

//---------app state
#[derive(Clone)]
struct AppState {
    pool: sqlx::MySqlPool,
}

#[tokio::main]
async fn main() -> Result<(), AppError> {
    dotenv().ok();
    let url = dotenv!("DATABASE_URL");
    let pool = sqlx::mysql::MySqlPool::connect(&url).await.map_err(|e| {
        AppError::new(
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("error connecting to db=>{}", e),
        )
    })?;

    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .map_err(|e| {
            AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("error migrating db=>{}", e),
            )
        })?;

    let app_state = AppState { pool };
    let app = Router::new()
        .route("/", get(|| async { "Hello, World!" }))
        .route("/notes", get(get_all_notes).post(post_note))
        .route(
            "/notes/:note_id",
            get(get_note).patch(update_note).delete(delete_note),
        )
        .route("/api_key", get(get_all_api_keys).delete(delete_api_key))
        .route("/api_key/:api_key_id", patch(update_api_key))
        .layer(middleware::from_fn_with_state(
            app_state.clone(),
            verify_api_key,
        ))
        .route("/api_key/new", post(generate_api_key))
        .with_state(app_state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();

    Ok(())
}

async fn get_all_notes(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
) -> Result<Json<NotesResponse>, AppError> {
    let query = "select * from notes where uid = ?";

    let row = sqlx::query(query)
        .bind(&user.uid)
        .fetch_all(&app_state.pool)
        .await
        .map_err(|_| {
            AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                "error getting users notes",
            )
        })?;

    let res: Vec<NoteResponse> = row
        .iter()
        .map(|row| NoteResponse {
            id: row.get("id"),
            uid: row.get("uid"),
            created_at: row.get("created_at"),
            title: row.get("title"),
            description: row.get("description"),
        })
        .collect();

    Ok(Json(NotesResponse { notes: res }))
}
async fn post_note(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
    Json(note_request): Json<NoteRequest>,
) -> Result<Json<NoteResponse>, AppError> {
    let id = Uuid::new_v4().to_string();

    let query = "INSERT INTO notes (id, uid, title, description) VALUES (?, ?, ?, ?)";

    sqlx::query(query)
        .bind(&id)
        .bind(&user.uid)
        .bind(&note_request.title)
        .bind(&note_request.description)
        .execute(&app_state.pool)
        .await
        .map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error creating note "))?;

    let query = "select * from notes where uid = ? and id = ?";
    let row = sqlx::query(query)
        .bind(&user.uid)
        .bind(&id)
        .fetch_one(&app_state.pool)
        .await
        .map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error fetching note "))?;
    // let a = type_of(row.get("created_at"));
    let res = NoteResponse {
        id: row.get("id"),
        uid: row.get("uid"),
        created_at: row.get("created_at"),
        title: row.get("title"),
        description: row.get("description"),
    };

    Ok(Json(res))
}
async fn get_note(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
    Path(note_id): Path<String>,
) -> Result<Json<NoteResponse>, AppError> {
    let query = "select * from notes where uid = ? and id = ?";
    let res = sqlx::query(query)
        .bind(&user.uid)
        .bind(&note_id)
        .fetch_optional(&app_state.pool)
        .await
        .map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error fetching note "))?
        .map(|row| NoteResponse {
            id: row.get("id"),
            uid: row.get("uid"),
            created_at: row.get("created_at"),
            title: row.get("title"),
            description: row.get("description"),
        });
    if res.is_some() {
        Ok(Json(res.unwrap()))
    } else {
        Err(AppError::new(
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Id => {} does not exist 🤯", note_id),
        ))
    }
}
async fn update_note(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
    Path(note_id): Path<String>,
    Json(note_request): Json<UpdateNoteRequest>,
) -> Result<Json<NoteResponse>, AppError> {
    //*===> update query start */
    let mut query = "UPDATE notes SET ".to_owned();

    if let Some(_) = note_request.title.clone() {
        query.push_str("title = ?, ");
    }

    if let Some(_) = note_request.description.clone() {
        query.push_str("description = ?, ");
    }

    query.pop();
    query.pop();
    query.push_str(" WHERE id = ? ");

    let result = if let Some(title) = note_request.title {
        if let Some(description) = note_request.description {
            sqlx::query(&query)
                .bind(&title)
                .bind(&description)
                .bind(&note_id)
                .execute(&app_state.pool)
                .await
        } else {
            sqlx::query(&query)
                .bind(&title)
                .bind(&note_id)
                .execute(&app_state.pool)
                .await
        }
    } else if let Some(description) = note_request.description {
        sqlx::query(&query)
            .bind(&description)
            .bind(&note_id)
            .execute(&app_state.pool)
            .await
    } else {
        return Err(AppError::new(
            StatusCode::BAD_REQUEST,
            "No value present to update ",
        ));
    };

    result.map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "Internal error"))?;
    //*===> update query end */
    //*===> fetch query start */
    let query = "select * from notes where uid = ? and id = ?";
    let row = sqlx::query(query)
        .bind(&user.uid)
        .bind(&note_id)
        .fetch_one(&app_state.pool)
        .await
        .map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error fetching note "))?;

    let res = NoteResponse {
        id: row.get("id"),
        uid: row.get("uid"),
        created_at: row.get("created_at"),
        title: row.get("title"),
        description: row.get("description"),
    };
    //*===> fetch query end */
    Ok(Json(res))
}

async fn delete_note(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
    Path(note_id): Path<String>,
) -> Result<StatusCode, AppError> {
    let query = "delete from notes where uid = ? and id = ?";
    sqlx::query(query)
        .bind(&user.uid)
        .bind(&note_id)
        .execute(&app_state.pool)
        .await
        .map_err(|_| {
            AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("unable to delete note with id {}", &note_id),
            )
        })?;
    Ok(StatusCode::OK)
}

async fn get_all_api_keys(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
) -> Result<Json<ApiKeysListResponse>, AppError> {
    let query = "select * from api_keys where uid = ?";

    let row = sqlx::query(query)
        .bind(&user.uid)
        .fetch_all(&app_state.pool)
        .await
        .map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error getting api keys"))?;

    let data: Vec<ApiKeysResponse> = row
        .iter()
        .map(|row| {
            let scope: Vec<String> = serde_json::from_str(row.get("scope")).unwrap();
            ApiKeysResponse {
                id: row.get("id"),
                name: row.get("name"),
                scope,
                prefix: row.get("prefix"),
            }
        })
        .collect();

    Ok(Json(ApiKeysListResponse { data }))
}
async fn generate_api_key(
    State(app_state): State<AppState>,
    Json(payload): Json<serde_json::Value>,
) -> Result<Json<ApiKeyResponse>, AppError> {
    //let user_id = Uuid::new_v4().to_string();
    if payload.get("name").is_none() | payload.get("scope").is_none() {
        return Err(AppError::new(
            StatusCode::BAD_REQUEST,
            "Expected key `name` or `scope` to be passed, but found null",
        ));
    }

    let name = payload.get("name").unwrap();
    let scope = payload.get("scope").unwrap();
    if let Some(email) = payload.get("email") {
        let prefix = Utc::now().timestamp().to_string();
        let api_key = Uuid::new_v4().to_string();
        let api_key = format!("{}.{}", &prefix, api_key);
        let hashed_api_key = hash_value(&api_key.as_str())?;

        //* =====> create user start */
        let user_id = Uuid::new_v4().to_string();

        let query = "INSERT INTO users (id, email) VALUES (?, ?)";

        sqlx::query(query)
            .bind(&user_id)
            .bind(&email)
            .execute(&app_state.pool)
            .await
            .map_err(|_| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error creating user"))?;
        //* =====> create user end */
        //* =====> create api key start */
        let id = Uuid::new_v4().to_string();

        let query = "INSERT INTO api_keys (id, uid, name, scope, api_key, prefix) VALUES (?, ?, ?, ?, ?, ?)";

        let json_scope = serde_json::to_string(&scope).map_err(|e| {
            AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("error getting scope ,,,{}", e),
            )
        })?;
        sqlx::query(query)
            .bind(&id)
            .bind(&user_id)
            .bind(&name)
            .bind(&json_scope)
            .bind(&hashed_api_key)
            .bind(&prefix)
            .execute(&app_state.pool)
            .await
            .map_err(|e| {
                AppError::new(
                    StatusCode::INTERNAL_SERVER_ERROR,
                    format!("error creating api key,{}", e),
                )
            })?;
        //* =====> create api key end */
        //* ======> get api key */
        let query = "select * from api_keys where uid = ? and id = ?";
        let res = sqlx::query(query)
            .bind(&user_id)
            .bind(&id)
            .fetch_optional(&app_state.pool)
            .await
            .map_err(|_| {
                AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error fetching api key ")
            })?
            .map(|row| {
                let scope: Vec<String> = serde_json::from_str(row.get("scope")).unwrap();
                ApiKeyResponse {
                    id: row.get("id"),
                    name: row.get("name"),
                    scope,
                    api_key,
                    prefix,
                }
            });
        if res.is_some() {
            Ok(Json(res.unwrap()))
        } else {
            Err(AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                "Error getting api key",
            ))
        }
    } else {
        return Err(AppError::new(
            StatusCode::BAD_REQUEST,
            "Expected key `email` to be passed, but gave null",
        ));
    }
}
async fn update_api_key(
    Path(api_key_id): Path<u32>,
    Extension(user): Extension<ApiMiddlewareResponse>,
) -> Result<StatusCode, AppError> {
    Err(AppError::new(
        StatusCode::INTERNAL_SERVER_ERROR,
        "Internal error",
    ))
}
async fn delete_api_key(
    State(app_state): State<AppState>,
    Extension(user): Extension<ApiMiddlewareResponse>,
) -> Result<StatusCode, AppError> {
    let query = "delete from api_keys where uid = ?";
    sqlx::query(query)
        .bind(&user.uid)
        .execute(&app_state.pool)
        .await
        .map_err(|_| {
            AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                "unable to delete api key with id provided",
            )
        })?;
    Ok(StatusCode::OK)
}

//---------hash
fn hash_value(value: &str) -> Result<String, AppError> {
    hash(value, 8)
        .map_err(|_error| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error encrypting key"))
}

fn verify_hashed_value(value: &str, hashed_value: &str) -> Result<bool, AppError> {
    verify(value, hashed_value)
        .map_err(|_error| AppError::new(StatusCode::INTERNAL_SERVER_ERROR, "error decrypting key"))
        .map(|_| true)
}

//-----middleware
async fn verify_api_key(
    State(app_state): State<AppState>,
    headers: HeaderMap,
    mut request: Request,
    next: Next,
) -> Result<Response, AppError> {
    if let Some(header_value) = headers.get("Api-key") {
        let value = header_value.to_str().unwrap();
        let prefix = value.split(".").collect::<Vec<&str>>()[0];

        //* get api key start */
        let query = "select * from api_keys where prefix = ?";
        let res = sqlx::query(query)
            .bind(&prefix)
            .fetch_optional(&app_state.pool)
            .await
            .map_err(|_| {
                AppError::new(
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "unable to retrieve api key",
                )
            })?
            .map(|row| {
                let scope: Vec<String> = serde_json::from_str(row.get("scope")).unwrap();
                ApiKeyMiddlewareResponse {
                    id: row.get("id"),
                    name: row.get("name"),
                    scope,
                    uid: row.get("uid"),
                    api_key: row.get("api_key"),
                    prefix: row.get("prefix"),
                }
            });
        //* get api key end */
        if res.is_none() {
            return Err(AppError::new(
                StatusCode::INTERNAL_SERVER_ERROR,
                "Unable to get api key",
            ));
        }

        let res = res.unwrap();
        verify_hashed_value(&value, &res.api_key)?;
        let res = ApiMiddlewareResponse {
            scope: res.scope,
            uid: res.uid,
        };

        request.extensions_mut().insert(res);
        Ok(next.run(request).await)
    } else {
        Err(AppError::new(
            StatusCode::INTERNAL_SERVER_ERROR,
            "No api key attached to this request",
        ))
    }
}
