# Deploy to Railway

## One-time Setup

### 1. Push code to GitHub
```
git init
git add .
git commit -m "initial commit"
# Create a repo on github.com, then:
git remote add origin https://github.com/YOUR_USERNAME/ireg.git
git push -u origin main
```

### 2. Create Railway project
1. Go to https://railway.app → Login with GitHub
2. Click **New Project** → **Deploy from GitHub repo** → select `ireg`
3. Set **Root Directory** to `backend`
4. Railway will detect the Dockerfile and start building

### 3. Add PostgreSQL
1. In Railway project → click **+ New** → **Database** → **PostgreSQL**
2. Railway automatically sets `DATABASE_URL` in your backend service — nothing to configure

### 4. Add environment variables to backend service
In Railway backend service → **Variables** tab → add:
```
FACE_SIMILARITY_THRESHOLD=0.4
MODEL_NAME=buffalo_sc
```
`DATABASE_URL` is already injected by Railway automatically.

### 5. Get your backend URL
Railway assigns a URL like: `https://ireg-backend-production.up.railway.app`
Copy it — you need it for the Flutter build.

---

## Deploy Flutter Web

### Build with your Railway backend URL
```bash
cd frontend
flutter build web --dart-define=API_URL=https://YOUR-BACKEND-URL.up.railway.app
```

### Deploy Flutter web to Railway
1. In Railway project → **+ New** → **Deploy from GitHub repo** → select `ireg` again
2. Set **Root Directory** to `frontend`
3. Add a `Dockerfile` in frontend (see below) OR use Netlify/Vercel for free Flutter web hosting

### Easier: Deploy Flutter web to Netlify (free)
1. Go to https://netlify.app → New site → drag & drop `frontend/build/web` folder
2. Done — free hosting for the Flutter web UI

---

## Costs on Railway
| Component | Cost |
|-----------|------|
| Backend (FastAPI) | ~$1-2/month |
| PostgreSQL | ~$0.50-1/month |
| **Total** | **~$2-3/month** |

Flutter web on Netlify = **$0**
