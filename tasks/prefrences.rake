require_relative '../helpers'

namespace :prefs do
  desc "Sets your preferred markdown editor"
  task :editor, :name do |t, args|
      Defaults.prefs["editor"] = args["name"]
      Defaults.save
  end
end
