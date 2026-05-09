import os
import io
import uvicorn
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import whisper
from pydantic import BaseModel

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = whisper.load_model("base")

class TranscriptionResponse(BaseModel):
    text: str

@app.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(file: UploadFile = File(...)):
    contents = await file.read()
    
    with open("/tmp/audio.m4a", "wb") as f:
        f.write(contents)
    
    result = model.transcribe("/tmp/audio.m4a", language="zh")
    
    os.remove("/tmp/audio.m4a")
    
    return {"text": result["text"]}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
