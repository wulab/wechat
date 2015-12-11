FROM ruby:2.2-onbuild
EXPOSE 4567
CMD ["ruby", "server.rb", "-e", "production", "-p", "4567"]