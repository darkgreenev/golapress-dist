docker-trial:
	docker build -t golapress-trial -f Dockerfile.trial .
	@echo "Starting trial container..."
	@echo "Default admin login: admin@example.com / admin12345"
	@echo "Access at: http://localhost:8076"
	docker run -it \
		-p 8076:8076 \
		-e MYSQL_DATABASE=golapress_trial \
		-e MYSQL_USER=golapress \
		-e MYSQL_PASSWORD=golapress \
		-e ADMIN_PASSWORD=admin12345 \
		golapress-trial
