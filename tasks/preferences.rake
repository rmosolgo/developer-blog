require_relative '../helpers'

namespace :prefs do
  desc "Sets your preferred markdown editor"
  task :editor, :name do |t, args|
    Defaults.prefs["editor"] = args["name"]
    Defaults.save
  end
  desc "Sets your preferred markdown viewer"
  task :preview, :name do |t, args|
    Defaults.prefs["write.preview"] = args["name"]
    Defaults.save
  end
end
