import pickle
from contextlib import asynccontextmanager

import pandas as pd
import requests
from scipy import cluster
import uvicorn
from fastapi import Depends, FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session

from methods import method
from models.models import UserProfile
from models.database import init_db, SessionLocal


###############입력데이터 모델 정리하는 곳
class UserInput(BaseModel):
    theme: str
    experience: str
    region: str

###############DB 세션 의존성 정의
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()



#########################################
###
###############시작시 활동 정리하는 곳
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


#########################################
app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origin=[],
    allow_credentials=False,
    allow_methods=["POST"],
    allow_header=["*"]
)

# K_MEANS_DATA_ROADED
k_means_df = pd.read_csv("./datas/K_means/clustered_mountains.csv")
scaler = None
kmeans = None
with open("./datas/K_means/scaler.pkl", "rb") as f:
    scaler = pickle.load(f)

with open("./datas/K_means/kmeans_model.pkl", "rb") as f:
    kmeans = pickle.load(f)


# 등산지수 API
@app.post("/weather")
async def weather():
    OPEN_WEATHER_LINK = "https://api.openweathermap.org/data/2.5/weather?lat=37.5665&lon=126.9780&units=metric&appid=052b29e73d62b1df3cac886dbc3641a0"
    DUST_LINK = "https://api.openweathermap.org/data/2.5/air_pollution?lat=37.5665&lon=126.9780&appid=052b29e73d62b1df3cac886dbc3641a0"

    weather_data = requests.get(OPEN_WEATHER_LINK).json()
    dust_data = requests.get(DUST_LINK).json()

    score = method.cal_score(weather_data, dust_data)

    return JSONResponse({"score": score})

@app.post("/recommend/{user_id}")
async def recommend(user_id:str, db: Session = Depends(get_db)):
    user = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if not user:
        return JSONResponse(
            status_code=400,
            content={"message": "설문을 먼저 생성하세요."}
        )
    
    user_input = UserInput(
        theme=user.theme,
        experience=user.experience,
        region=user.region
    )

    user_vector = method.make_user_vector(user_input.model_dump(), scaler)
    scaled_vec = scaler.transform(user_vector)
    cluster_label = kmeans.predict(scaled_vec)[0]

    matched = k_means_df[k_means_df["cluster"] == cluster_label]
    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")

    for rec_data in recommendations:
        rec_data["image_url"] = method.get_image_by_mountain_name(rec_data["mountain_name"])

    return JSONResponse({
        "cluster": int(cluster_label),
        "recommendations": recommendations
    })



if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
