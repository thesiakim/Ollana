from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import Json
import uvicorn
import requests
from methods import cal

app = FastAPI()

# 등산지수 API
@app.get("/weather")
async def weather():
    OPEN_WEATHER_LINK="https://api.openweathermap.org/data/2.5/weather?lat=37.5665&lon=126.9780&units=metric&appid=052b29e73d62b1df3cac886dbc3641a0"
    DUST_LINK="https://api.openweathermap.org/data/2.5/air_pollution?lat=37.5665&lon=126.9780&appid=052b29e73d62b1df3cac886dbc3641a0"
    
    weather_data = requests.get(OPEN_WEATHER_LINK).json()
    dust_data = requests.get(DUST_LINK).json()
    
    score = cal.cal_score(weather_data, dust_data)
    
    return JSONResponse({"score": score})

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)