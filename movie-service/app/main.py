from fastapi import FastAPI
from app.api.movies import movies
from app.api.db import metadata, database, engine
from app.health import router as health_router

metadata.create_all(engine)

app = FastAPI(
    title="Movie Service",
    description="API for movies",
    openapi_url="/api/v1/movies/openapi.json", 
    docs_url="/api/v1/movies/docs"
)

@app.on_event("startup")
async def startup():
    try:
        await database.connect()
        print("✅ Movie service database connected")
    except Exception as e:
        print(f"⚠️ Movie service database connection failed: {e}")

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

app.include_router(health_router)
app.include_router(movies, prefix='/api/v1/movies', tags=['movies'])
