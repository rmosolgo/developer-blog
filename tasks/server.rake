require_relative '../helpers'

desc 'Runs the jekyll server.'
task :server do
  `open http://localhost:4000`
  exec "bundle exec jekyll serve --watch"
end
