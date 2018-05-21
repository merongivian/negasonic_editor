require 'opal'
require 'opal-parser'
require 'opal-jquery'
require 'negasonic'

%x{
  StartAudioContext(Tone.context).then(function(){
    Tone.Transport.start("+0.1")
  })
}

class TryNegasonic
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

    @output = Editor.new :output, lineNumbers: false, mode: 'text', readOnly: true
    @editor = Editor.new :editor, lineNumbers: true, mode: 'ruby', tabMode: 'shift', theme: 'tomorrow-night-eighties', extraKeys: {
      'Cmd-Enter' => -> { run_code }
    }

    @link = Element.find('#link_code')
    Element.find('#run_code').on(:click) { run_code }
    Element.find('#stop').on(:click) { stop_negasonic }

    hash = `decodeURIComponent(location.hash || location.search)`

    if hash =~ /^[#?]code:/
      @editor.value = hash[6..-1]
    end
  end

  def stop_negasonic
    %x{
      if (Tone.Transport.state == 'started') {
        Tone.Transport.stop("+0.1")
      };
    }
  end

  def reset_negasonic
    Negasonic::LoopedEvent.dispose_all

    %x{
      if (Tone.Transport.state == 'stopped') {
        Tone.Transport.start("+0.1")
      };
    }
  end

  def run_code
    reset_negasonic
    @flush = []
    @output.value = ''

    @link[:href] = "?code:#{`encodeURIComponent(#{@editor.value})`}"

    begin
      code = Opal.compile(@editor.value, :source_map_enabled => false)
      eval_code code
    rescue => err
      log_error err
    end
  end

  def eval_code(js_code)
    `eval(js_code)`
  end

  def log_error(err)
    puts "#{err}\n#{`err.stack`}"
  end

  def print_to_output(str)
    @flush << str
    @output.value = @flush.join('')
  end
end

Document.ready? do
  $stdout.write_proc = $stderr.write_proc = proc do |str|
    TryNegasonic.instance.print_to_output(str)
  end
  TryNegasonic.instance.run_code
end
