API_CONTAINER=muybien-api
WEB_CONTAINER=muybien-web

# ─────────────────────────────────────────
# ローカル開発
# ─────────────────────────────────────────
# up:
# 	docker-compose up --build -d
# 	@echo "起動完了 → http://localhost:5173"
# 	@echo "DB が必要な場合: make db-up  または  make up-all"

up:
	docker-compose --profile db up --build -d
	@echo "起動完了（DB 含む）→ http://localhost:5173"

db-up:
	docker-compose --profile db up -d myapp-db

init-db:
	@echo "DB の起動を待機中..."
	@i=0; while [ $$i -lt 30 ]; do \
		docker exec muybien-db pg_isready -U postgres >/dev/null 2>&1 && break; \
		i=$$((i + 1)); sleep 1; \
	done
	@docker exec muybien-db pg_isready -U postgres >/dev/null 2>&1 \
		|| (echo "❌ muybien-db が起動していません。make up を実行してください。" && exit 1)
	@docker exec muybien-db psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'muybiendb'" | grep -q 1 \
		|| docker exec muybien-db psql -U postgres -c "CREATE DATABASE muybiendb;"
	@echo "DB muybiendb を確認しました"

migrate: init-db
	docker exec $(API_CONTAINER) python manage.py migrate

makemigrations:
	docker exec $(API_CONTAINER) python manage.py makemigrations

createsuperuser:
	docker exec -it $(API_CONTAINER) python manage.py createsuperuser

down:
	docker-compose --profile db down

restart: down up

logs:
	docker-compose logs -f --tail=200

api-logs:
	docker logs -f $(API_CONTAINER)

api-bash:
	docker exec -it $(API_CONTAINER) bash

web-bash:
	docker exec -it $(WEB_CONTAINER) sh

# ─────────────────────────────────────────
# フロントエンドビルド（デプロイ前に実行）
# ─────────────────────────────────────────
build-front:
	cd myapp-web/app && npm run build

# ─────────────────────────────────────────
# 本番デプロイ（muy = EC2）
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
