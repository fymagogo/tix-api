web: bin/rails server -p ${PORT:-3000} -b 0.0.0.0
worker: bundle exec sidekiq
release: bin/rails db:migrate
