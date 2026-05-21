# Deployment Plan (Free-Cost) - Smart Ride Sharing System

## Goal
Deploy the complete project at zero cost using:
- Oracle Cloud Always Free VM for backend microservices + MySQL
- Vercel or Netlify (free tier) for React frontend

## Scope
Backend services:
- `eureka-server`
- `user-service`
- `ride-service`
- `payment-service`
- `api-gateway-service`

Frontend:
- `fronted_ride_share`

---

## Phase 1: Stabilize and Prepare the Codebase
1. Verify all services run locally in this order:
   1. `eureka-server`
   2. `user-service`
   3. `ride-service`
   4. `payment-service`
   5. `api-gateway-service`
2. Verify frontend runs and can call APIs through gateway.
3. Create a safe restore point:
   - Push latest branch to GitHub.
   - Add a release tag before deployment changes.
4. Move secrets to environment variables:
   - DB username/password
   - JWT secret
   - Razorpay keys
   - Any API keys

Deliverable:
- Local project runs cleanly with secrets externalized.

---

## Phase 2: Containerize the Backend
1. Add a `Dockerfile` to each backend service.
2. Create root-level `docker-compose.yml` including:
   - `mysql`
   - `eureka-server`
   - `user-service`
   - `ride-service`
   - `payment-service`
   - `api-gateway-service`
3. Replace `localhost` references with Docker service names where needed.
4. Add health checks and restart policies.
5. Add `.env.example` documenting required environment variables.

Deliverable:
- Full backend stack starts with a single `docker compose up -d` locally.

---

## Phase 3: Provision Oracle Cloud Always Free VM
1. Create Oracle Cloud Always Free account and tenancy.
2. Create Ubuntu VM (Always Free eligible shape).
3. Reserve a public IP.
4. Configure security list / NSG:
   - Open `22`, `80`, `443`
   - Keep service ports (`8080`, `8761`, etc.) private whenever possible
5. Basic hardening:
   - SSH key auth only
   - Disable password login
   - Create non-root admin user
   - Configure firewall

Deliverable:
- Secure, reachable VM ready for deployment.

---

## Phase 4: Install Runtime and Deploy Backend
1. Install Docker Engine and Docker Compose plugin.
2. Install Git.
3. Clone repository on VM.
4. Create `.env` with production values.
5. Start backend stack:
   - `docker compose up -d --build`
6. Validate:
   - Eureka UI reachable internally
   - Services register in Eureka
   - Gateway routes requests correctly

Deliverable:
- Backend services running on Oracle VM.

---

## Phase 5: Public Access via Nginx + HTTPS
1. Install Nginx on VM.
2. Configure reverse proxy:
   - Domain -> Nginx -> API Gateway (`8080` internal)
3. Issue SSL certificate with Let's Encrypt.
4. Enforce HTTPS redirection.
5. Restrict direct public access to internal service ports.

Deliverable:
- Secure public API endpoint over HTTPS.

---

## Phase 6: Deploy Frontend (Vercel or Netlify)
1. Connect repository/folder: `fronted_ride_share`.
2. Configure environment variable:
   - `VITE_API_BASE_URL=https://<your-domain>/api`
3. Run build and deploy.
4. Validate full user flows:
   - Login/Register
   - Ride operations
   - Payment test mode flow

Deliverable:
- Public frontend connected to deployed backend.

---

## Phase 7: Production Readiness
1. Set CORS to only allow frontend domain.
2. Tune JVM memory limits for each service.
3. Add Docker restart policies.
4. Add daily MySQL backups (cron job).
5. Add uptime monitoring (for example UptimeRobot free tier).

Deliverable:
- Basic reliability and operational safety in place.

---

## Phase 8: Free CI/CD Automation
1. Create GitHub Actions workflow:
   - Build images or artifacts on push to `main`
   - SSH into VM
   - Pull latest code/images
   - Run `docker compose up -d`
2. Add optional manual approval before production deployment.

Deliverable:
- Repeatable one-command/one-pipeline deployment process.

---

## Validation Checklist
- [ ] Eureka starts and shows all services registered
- [ ] API Gateway routes requests to each service
- [ ] MySQL connection stable across services
- [ ] Frontend can access backend over HTTPS
- [ ] JWT auth works in deployed environment
- [ ] Payment service works in Razorpay test mode
- [ ] CORS and security headers correctly configured
- [ ] Backups run and can be restored

---

## Rollback Plan
1. Keep previous Docker image tags.
2. Keep previous `docker-compose.yml` and `.env` backup.
3. On failure:
   - Revert to prior image tag(s)
   - Restart stack with known-good compose config
4. Validate gateway health and key user flows immediately.

---

## Suggested Execution Order
1. Containerize all backend services locally.
2. Validate full compose stack locally.
3. Provision and harden Oracle VM.
4. Deploy backend stack to VM.
5. Configure Nginx + SSL.
6. Deploy frontend on Vercel/Netlify.
7. Final validation, backup setup, and CI/CD automation.

---

## Notes
- Free tiers have resource limits; monitor memory and CPU usage.
- Keep services lightweight (JVM flags, connection pool limits).
- Prefer internal networking for microservice traffic; expose only what is required.
