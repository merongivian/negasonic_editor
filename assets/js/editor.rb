require 'opal'
require 'opal-parser'
require 'opal-jquery'
require 'negasonic'

%x{
  StartAudioContext(Tone.context).then(function(){
    Tone.Transport.start("+0.1")
  })
}

class TryOpal
  class Editor
    def initialize(dom_id, options)
      @native = `CodeMirror(document.getElementById(dom_id), #{options.to_n})`
    end

    def value=(str)
      `#@native.setValue(str)`
    end

    def value
      `#@native.getValue()`
    end
  end

  def self.instance
    @instance ||= self.new
  end

  def initialize
    @flush = []

    @editor = Editor.new :editor, lineNumbers: true, mode: 'ruby', tabMode: 'shift', theme: 'tomorrow-night-eighties', extraKeys: {
      'Cmd-Enter' => -> { run_code }
    }

    @link = Element.find('#link_code')
    Element.find('#run_code').on(:click) { run_code }

    hash = `decodeURIComponent(location.hash || location.search)`

    if hash =~ /^[#?]code:/
      @editor.value = hash[6..-1]
    end
  end

  def run_code
    replay
    @flush = []

    @link[:href] = "?code:#{`encodeURIComponent(#{@editor.value})`}"

    begin
      code = Opal.compile(@editor.value, :source_map_enabled => false)
      eval_code code
    rescue => err
      log_error err
    end
  end

  def replay
    #universe.events.dispose
    Negasonic::LoopedEvent.dispose_all
    #after(0.5) do
      #NegaSonic.dispose_synths_effects
    #end
    #Tone::Transport.start("+0.1")
  end

  def eval_code(js_code)
    `eval(js_code)`
  end

  def log_error(err)
    puts "#{err}\n#{`err.stack`}"
  end
end

Document.ready? do
  TryOpal.instance.run_code
end
