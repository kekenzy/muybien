API_CONTAINER=muybien-api
WEB_CONTAINER=muybien-web

# ─────────────────────────────────────────
# ローカル開発
# ─────────────────────────────────────────
up:
	docker-compose up --build -d
	@echo "起動完了 → http://localhost:5173"

down:
	docker-compose down

restart: down up

logs:
	docker-compose logs -f --tail=200

api-logs:
	docker logs -f $(API_CONTAINER)

api-bash:
	docker exec -it $(API_CONTAINER) bash

web-bash:
	docker exec -it $(WEB_CONTAINER) sh

migrate:
	docker exec $(API_CONTAINER) python manage.py migrate

makemigrations:
	docker exec $(API_CONTAINER) python manage.py makemigrations

createsuperuser:
	docker exec -it $(API_CONTAINER) python manage.py createsuperuser

# ─────────────────────────────────────────
# フロントエンドビルド（デプロイ前に実行）
# ─────────────────────────────────────────
build-front:
	cd myapp-web/app && npm run build

# ─────────────────────────────────────────
# 本番デプロイ（pfweb = Lightsail）
# ─────────────────────────────────────────
prod-deploy:
	@bash scripts/deploy.sh

prod-logs:
	@bash scripts/prod-logs.sh

prod-migrate:
	@bash scripts/prod-migrate.sh

prod-bash:
	@bash scripts/prod-bash.sh

prod-down:
	@bash scripts/prod-down.sh

deploy: prod-deploy
