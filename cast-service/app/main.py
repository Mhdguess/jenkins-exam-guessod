from fastapi import FastAPI
from app.api.casts import casts
from app.api.db import metadata, database, engine
from app.health import router as health_router

metadata.create_all(engine)

app = FastAPI(
    title="Cast Service",
    description="API for casts",
    openapi_url="/api/v1/casts/openapi.json", 
    docs_url="/api/v1/casts/docs"
)

@app.on_event("startup")
async def startup():
    try:
        await database.connect()
        print("✅ Cast service database connected")
    except Exception as e:
        print(f"⚠️ Cast service database connection failed: {e}")

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

app.include_router(health_router)
app.include_router(casts, prefix='/api/v1/casts', tags=['casts'])
