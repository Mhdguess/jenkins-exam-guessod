from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "movie-service"}

@router.get("/")
async def root():
    return {"message": "Movie Service API", "docs": "/api/v1/movies/docs"}
