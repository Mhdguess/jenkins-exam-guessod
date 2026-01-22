from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "cast-service"}

@router.get("/")
async def root():
    return {"message": "Cast Service API", "docs": "/api/v1/casts/docs"}
