require 'opal'
require 'opal-parser'
require 'opal-jquery'
require 'negasonic'

DEFAULT_TRY_CODE = <<-RUBY
instrument(:drums, synth: :membrane) do
  effects do
    bit_crusher bits: 3
    distortion value: 0.8
  end
end

pattern(instrument: :drums, interval: '4n', type: :up_down, notes: ["E1", "C3"])
pattern(instrument: :drums, interval: '2t', type: :up_down, notes: ["F2"])

instrument(:mid, synth: :am) do
  effects do
    vibrato frequency: 5
    feedback_delay
  end
end

pattern(instrument: :mid, interval: '1n', type: :random_walk, notes: ["E5", 'C4', 'F5'])

instrument(:high, synth: :poly, volume: -11) do
  effects do
    feedback_delay delay_time: 0.5
    freeverb
  end
end

pattern(instrument: :high, interval: '8n', type: :down_up, notes: ["E6", 'G6', 'F6', 'A6'])
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
    Element.find('#stop').on(:click) { Negasonic::Time.stop }

    hash = `decodeURIComponent(location.hash || location.search)`

    if hash =~ /^[#?]code:/
      @editor.value = hash[6..-1]
		else
			@editor.value = DEFAULT_TRY_CODE.strip
    end
  end

  def start_negasonic
    if Tone::Transport.stopped?
      %x{
        StartAudioContext(Tone.context).then(function(){
          Tone.Master.volume.value = -20;
          #{Tone::Transport.start}
        })
      }

      Negasonic::Time.set_next_cycle_number_acummulator
    end
  end

  def run_code
    start_negasonic

    @flush = []
    @output.value = ''

    set_link_code

    begin
      Negasonic::Instrument.set_all_to_not_used

      Negasonic.default_instrument.store_current_cycles
      Negasonic.default_instrument.reload

      code = Opal.compile(@editor.value, :source_map_enabled => false)
      eval_code code

      Negasonic::Time.schedule_next_cycle do
        Negasonic.default_instrument.dispose_stored_cycles
        Negasonic.default_instrument.start_current_cycles

        Negasonic::Instrument.all_not_used.each(&:kill_current_cycles)
      end

      Negasonic::Time.just_started = false
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
