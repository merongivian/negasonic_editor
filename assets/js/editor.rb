require 'opal'
require 'opal-parser'
require 'opal-jquery'
require 'negasonic'

DEFAULT_TRY_CODE = <<-RUBY
instrument(:bass, synth: :fm, volume: 9) do
  effects do
    #vibrato
    #distortion
    #feedback_delay
    jc_reverb
  end
end

pattern(instrument: :bass, interval: '1n', type: :down_up, notes: ["C2", "D2", "E2", "A2"])

instrument(:lead, synth: :am, volume: 1) do
  effects do
    vibrato frequency: 5, depth: 0.1
    #distortion
    feedback_delay delay_time: 0.25, feedback: 0.5
    jc_reverb room_size: 0.5
  end
end

pattern(instrument: :lead, interval: '8n', type: :random_walk, notes: ["C5", "D6", "E5", "A6"])

instrument(:drums, synth: :membrane) do
  effects do
    #vibrato
    distortion value: 0.4
    #feedback_delay
    #jc_reverb
  end
end

pattern(instrument: :drums, interval: '12n', type: :up_down, notes: ["C2", "D4", "E1", "D1"])
RUBY

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
		else
			@editor.value = DEFAULT_TRY_CODE.strip
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
        StartAudioContext(Tone.context).then(function(){
          Tone.Master.volume.value = -20;
          Tone.Transport.start("+0.1");
        })
      };
    }
  end

  def run_code
    reset_negasonic
    @flush = []
    @output.value = ''

    set_link_code

    begin
      code = Opal.compile(@editor.value, :source_map_enabled => false)
      eval_code code
    rescue => err
      log_error err
    end
  end

  def set_link_code
    @link[:href] = "?code:#{`encodeURIComponent(#{@editor.value})`}"
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
  TryNegasonic.instance.set_link_code
end
