COMPOSE = docker compose -f srcs/docker-compose.yml -p $(NAME)

all: up

up:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

clean: down

fclean:
	@$(COMPOSE) down --rmi all -v

re: fclean up

.PHONY: all up down clean fclean re
