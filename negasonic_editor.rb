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
      Keen.publish(
        :editor,
        ip_address: request.ip,
        keen: {
                addons: [
                  {
                    name: 'keen:ip_to_geo',
                    input: { ip: 'ip_address' },
                    output: 'ip_geo_info'
                  }
                ]
              }
      )
      view('editor')
    end
  end

  define_method(:js)         { |file| assets.js file }
  define_method(:stylesheet) { |file| assets.stylesheet file }
end
