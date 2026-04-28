FROM node:20-alpine AS client-build
WORKDIR /app/client/board-frontend
COPY client/board-frontend/package*.json ./
RUN npm install
COPY client/board-frontend/ ./
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
COPY --from=client-build /app/client/board-frontend/dist ./client/board-frontend/dist
EXPOSE 3001
CMD ["node", "server.js"]
