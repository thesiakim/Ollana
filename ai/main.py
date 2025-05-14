import pickle
from contextlib import asynccontextmanager

import numpy as np
import pandas as pd
import requests
from scipy import cluster
import uvicorn
from fastapi import Depends, FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Body
from pydantic import BaseModel
from sqlalchemy.orm import Session

from methods import method
from models.models import UserProfile
from models.database import init_db, SessionLocal

import tensorflow as tf
import joblib

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

# 유저 설문 제출 API
@app.post("/submit_survey/{user_id}")
async def submit_suervey(user_id: str, user_input:UserInput, db:Session = Depends(get_db)):
    if not user_id:
        return JSONResponse(status_code=400, content={"message": "유효한 user_id를 query 파라미터로 전달해주세요."})
    
    user = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    print("📁 DB 실제 경로:", SessionLocal().bind.url)
    if user:
        user.theme = user_input.theme
        user.experience = user_input.experience
        user.region = user_input.region
    else:
        user = UserProfile(
            user_id=user_id,
            theme=user_input.theme,
            experience=user_input.experience,
            region=user_input.region
        )
        db.add(user)
        db.flush()
        
    db.commit()
    return JSONResponse({"message": "설문이 성공적으로 저장되었습니다."})
    
# 유저 설문 기반 추천(클러스터링)
@app.post("/recommend/{user_id}")
async def recommend(user_id:str, db: Session = Depends(get_db)):
    # 설문데이터 sqlite에서 찾기
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
    
    # 유저의 백터 검색
    user_vector = method.make_user_vector(user_input.model_dump(), scaler)
    scaled_vec = scaler.transform(user_vector)
    cluster_label = kmeans.predict(scaled_vec)[0]

    matched = k_means_df[k_means_df["cluster"] == cluster_label]
    # 이름과 설명을 찾기
    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")

    # 이미지 URL 찾기
    for rec_data in recommendations:
        rec_data["image_url"] = method.get_image_by_mountain_name(rec_data["mountain_name"])

    return JSONResponse({
        "cluster": int(cluster_label),
        "recommendations": recommendations
    })

# 키워드 기반 검색 API
@app.post("/recommend_by_keyword")
async def recommend_by_keyword(keyword: str = Body(..., embed=True)):
    # 사용자가 입력한 키워드
    theme_col = f"has_{keyword}"

    # 키워드 검사
    if theme_col not in k_means_df.columns:
        return JSONResponse(
            status_code=400,
            content={"message": f"유효하지 않은 키워드입니다: {keyword}"}
        )

    # 키워드 추출
    matched = k_means_df[k_means_df[theme_col] > 0]

    # 비었는지 체크
    if matched.empty:
        return JSONResponse(
            status_code=404,
            content={"message": f"'{keyword}' 키워드를 포함한 산을 찾을 수 없습니다."}
        )

    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")

    for rec_data in recommendations:
        image_url = method.get_image_by_mountain_name(rec_data["mountain_name"])
        rec_data["image_url"] = image_url or "https://image.ytn.co.kr/general/jpg/2020/0924/202009241540389154_d.jpg"
    return JSONResponse({
        "keyword": keyword,
        "recommendations": recommendations
    })

# 지역 기반 검색 API
@app.post("/recommend_by_region")
async def recommend_by_region(region: str = Body(..., embed=True)):
    matched = k_means_df[k_means_df["region"] == region]
    
    if matched.empty:
        return JSONResponse(
            status_code=404,
            content={"message": f"'{region}' 지역의 산 정보를 찾을 수 없습니다."}
        )
    
    recommendations = matched.sample(n=min(3, len(matched)))[
        ["mountain_name", "mountain_description"]
    ].to_dict(orient="records")
    
    for rec_data in recommendations:
        image_url = method.get_image_by_mountain_name(rec_data["mountain_name"])
        rec_data["image_url"] = image_url or "https://image.ytn.co.kr/general/jpg/2020/0924/202009241540389154_d.jpg"

    return JSONResponse({
        "region": region,
        "recommendations": recommendations
    })


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
