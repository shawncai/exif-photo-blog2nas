# Dockerfile for exif-photo-blog
FROM node:20-alpine AS base

# 1. Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm (using version from package.json)
RUN corepack enable && corepack prepare pnpm@10.29.1 --activate

# Copy package files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm i --no-frozen-lockfile

# 2. Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@10.29.1 --activate

# Copy node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules
# Copy all source files (will ignore node_modules thanks to .dockerignore)
COPY . .

# Environment variables for build process
ARG NEXT_PUBLIC_STORAGE_PREFERENCE=minio
ARG NEXT_PUBLIC_MINIO_BUCKET
ARG NEXT_PUBLIC_MINIO_DOMAIN
ARG NEXT_PUBLIC_MINIO_PORT
ARG NEXT_PUBLIC_MINIO_DISABLE_SSL

ENV NEXT_PUBLIC_STORAGE_PREFERENCE=$NEXT_PUBLIC_STORAGE_PREFERENCE
ENV NEXT_PUBLIC_MINIO_BUCKET=$NEXT_PUBLIC_MINIO_BUCKET
ENV NEXT_PUBLIC_MINIO_DOMAIN=$NEXT_PUBLIC_MINIO_DOMAIN
ENV NEXT_PUBLIC_MINIO_PORT=$NEXT_PUBLIC_MINIO_PORT
ENV NEXT_PUBLIC_MINIO_DISABLE_SSL=$NEXT_PUBLIC_MINIO_DISABLE_SSL

ENV POSTGRES_URL=postgres://dummy:dummy@localhost:5432/dummy
ENV AUTH_SECRET=dummy_secret
ENV NEXT_TELEMETRY_DISABLED 1

# Build the project
RUN pnpm build

# 3. Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
