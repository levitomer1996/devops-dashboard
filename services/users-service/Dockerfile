# ---------- build stage ----------
FROM node:20-alpine AS build
WORKDIR /app

# Faster installs with frozen lockfile
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# ---------- run stage ----------
FROM node:20-alpine
WORKDIR /app

ENV NODE_ENV=production
# If your app reads PORT from env (recommended)
ENV PORT=3000

# Install only production deps
COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled code
COPY --from=build /app/dist ./dist

# (Optional) run as non-root for security
# RUN addgroup -S app && adduser -S app -G app
# USER app

EXPOSE 3000
CMD ["node", "dist/main.js"]
