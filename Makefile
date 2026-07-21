API_CONTAINER=muybien-api
WEB_CONTAINER=muybien-web

# docker グループ未所属時は sudo（本番サーバー等）
DOCKER := $(shell docker info >/dev/null 2>&1 && echo docker || echo sudo docker)

.PHONY: local-urls

# ─────────────────────────────────────────
# ローカル開発
# ─────────────────────────────────────────
local-urls:
	@echo ""
	@echo "ローカル URL:"
	@echo "  フロント           http://localhost:5173"
	@echo "  Lab ログイン       http://localhost:5173/lab/login"
	@echo "  顧客ポータル       http://localhost:5173/portal/login"
	@echo "  API                http://localhost:8000/v1/api/contact"
	@echo "  Django Admin       http://localhost:8000/admin/"
	@echo "  Mailpit            http://localhost:8025"
	@echo ""

# up:
# 	docker-compose up --build -d
# 	@$(MAKE) --no-print-directory local-urls

up:
	docker-compose --profile db up --build -d
	@$(MAKE) --no-print-directory local-urls

db-up:
	docker-compose --profile db up -d myapp-db

init-db:
	@echo "DB の起動を待機中..."
	@i=0; while [ $$i -lt 30 ]; do \
		$(DOCKER) exec muybien-db pg_isready -U postgres >/dev/null 2>&1 && break; \
		i=$$((i + 1)); sleep 1; \
	done
	@$(DOCKER) exec muybien-db pg_isready -U postgres >/dev/null 2>&1 \
		|| (echo "❌ muybien-db が起動していません。make up を実行してください。" && exit 1)
	@$(DOCKER) exec muybien-db psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'muybiendb'" | grep -q 1 \
		|| $(DOCKER) exec muybien-db psql -U postgres -c "CREATE DATABASE muybiendb;"
	@echo "DB muybiendb を確認しました"

migrate: init-db
	$(DOCKER) exec $(API_CONTAINER) python manage.py migrate

makemigrations:
	$(DOCKER) exec $(API_CONTAINER) python manage.py makemigrations

createsuperuser:
	$(DOCKER) exec -it $(API_CONTAINER) python manage.py createsuperuser

down:
	docker-compose --profile db down

restart: down up

# 未使用の Docker リソースをクリア（イメージ・コンテナ・ネットワーク・ビルドキャッシュ）
# ※ ボリュームは削除しない（DB データ保護）
docker-refresh:
	@echo "未使用の Docker リソースを削除します（ボリュームは対象外）..."
	$(DOCKER) system prune -af
	$(DOCKER) builder prune -af
	@echo "完了"

logs:
	docker-compose logs -f --tail=200

api-logs:
	$(DOCKER) logs -f $(API_CONTAINER)

api-bash:
	$(DOCKER) exec -it $(API_CONTAINER) bash

web-bash:
	$(DOCKER) exec -it $(WEB_CONTAINER) sh

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

prod-createsuperuser:
	@bash scripts/prod-createsuperuser.sh

prod-bash:
	@bash scripts/prod-bash.sh

prod-down:
	@bash scripts/prod-down.sh

deploy: prod-deploy
