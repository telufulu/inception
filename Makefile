NAME		= inception
COMPOSE 	= docker compose -f srcs/docker-compose.yml -p $(NAME)
DATA_DIR	= /home/$(USER)/data

all: up

up:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

logs:
	@$(COMPOSE) logs -f

ps:
	@$(COMPOSE) ps

clean: down

fclean:
	@$(COMPOSE) down --rmi all -v
	@rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

re: fclean up

.PHONY: all up down logs ps clean fclean re
