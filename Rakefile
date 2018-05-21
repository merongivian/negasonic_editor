require 'bundler/setup'
require 'opal'
require 'tone'
require 'negasonic'
require 'roda/opal_assets'

# Keep a single asset compiler in case we want to use it for multiple tasks.
assets = Roda::OpalAssets.new(env: :production)

desc 'Precompile assets for production'
task 'assets:precompile' do
  assets << 'editor.js'
  assets.build
end
