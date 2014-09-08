require 'digest'

namespace :gravatar do
  desc "Takes your email, and generates a Gravitar URL"
  task :link, :email do |t, args|
    hash = Digest::MD5.hexdigest args["email"]
    puts "http://www.gravatar.com/avatar/#{hash}"
  end
end
