require 'opal'
require 'roda'
require 'roda/opal_assets'

class NegasonicEditor < Roda
  plugin :render
  assets = Roda::OpalAssets.new

  route do |r|
    assets.route r

    r.root do
      view('editor')
    end
  end

  define_method(:js)         { |file| assets.js file }
  define_method(:stylesheet) { |file| assets.stylesheet file }
end
