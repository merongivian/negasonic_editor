require 'opal'
require 'opal-parser'
require 'opal-jquery'
require 'negasonic'

DEFAULT_TRY_CODE = <<-RUBY
# playing notes in the default cycle
play 62, 63, 65
play 69, 70, 74

# sounds at the same time as the previous notes
cycle do
  play 74, 70, 69
  play 65, 63, 62
end

# add custom effects and a synth
with_instrument(:drums, synth: :membrane, fx: [:distortion, :freeverb], volume: -9) do
  cycle do
    2.times do
     play 30
     play 64
    end
  end

  cycle do
    1.times do
      play 95
      play 64
      play 85
    end
  end
end
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
