FROM node:lts

ARG NODE_ENV=production
ENV NODE_ENV ${NODE_ENV}

WORKDIR /app

ARG PORT=80
ENV PORT ${PORT}
EXPOSE ${PORT} 9876

COPY package.json /app/package.json
COPY package-lock.json /app/package-lock.json
RUN npm ci

COPY . /app

CMD ["npm", "run", "dev"]