require 'bundler/setup'
require 'opal'
require 'opal-jquery'
require 'tone'
require 'negasonic'
require 'roda/opal_assets'

# Keep a single asset compiler in case we want to use it for multiple tasks.
assets = Roda::OpalAssets.new(env: :production)

desc 'Precompile assets for production'
task 'assets:precompile' do
  assets << 'codemirror.js' << 'jquery.js' << 'ruby.js' << 'start_audio_context.js' << 'editor.js' << 'app.css' << 'codemirror-solarized.css' << 'codemirror.css'
  assets.build
end
