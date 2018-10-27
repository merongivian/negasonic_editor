require 'opal'
require 'roda'
require 'roda/opal_assets'
require 'keen'

class NegasonicEditor < Roda
  plugin :render
  plugin :public

  assets = Roda::OpalAssets.new

  route do |r|
    r.public

    assets.route r

    r.root do
      Keen.publish(:editor, {})
      view('editor')
    end
  end

  define_method(:js)         { |file| assets.js file }
  define_method(:stylesheet) { |file| assets.stylesheet file }
end
