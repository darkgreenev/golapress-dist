docker-with-data:
	docker build -t golapress-with-data -f Dockerfile.withData .
	@echo "Starting with-data container..."
	@echo "Default admin login: admin@example.com / admin12345"
	@echo "Access at: http://localhost:8076"
	docker run -it \
		-p 8076:8076 \
		-e MYSQL_DATABASE=golapress_trial \
		-e MYSQL_USER=golapress \
		-e MYSQL_PASSWORD=golapress \
		-e ADMIN_PASSWORD=admin12345 \
		golapress-with-data

docker-standard:
	docker build -t golapress-standard -f Dockerfile.standard .
	@echo "Starting standard container..."
	@echo "Default admin login: admin@example.com / admin12345"
	@echo "Access at: http://localhost:8076"
	docker run -it \
		-p 8076:8076 \
		-v "$(shell pwd)/data":/app/data \
		golapress-standard
