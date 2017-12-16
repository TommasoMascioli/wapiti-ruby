module Wapiti
  require 'builder'

  class Sequence
    extend Forwardable
    include Comparable
    include Enumerable

    attr_reader :tokens
    def_delegators :tokens, :[], :size

    class << self
      def parse(string, delimiter: /\r?\n/, **options)
        new(string.split(delimiter).map { |token|
          Token.parse token, **options
        })
      end
    end

    def initialize(tokens = [])
      @tokens = tokens
    end

    def <=>(other)
    end

    def tagged?
      all?(&:label?)
    end

    def each
      if block_given?
        tokens.each(&Proc.new)
        self
      else
        to_enum
      end
    end

    alias_method :each_token, :each

    def each_segment(spacer: ' ')
      if block_given?
        lbl, sgm = nil, []

        each do |tk|
          if lbl != tk.label
            yield [lbl, sgm.join(spacer)] unless sgm.empty?
            lbl, sgm = tk.label, [tk.value]
          else
            sgm << tk.value
          end
        end

        yield [lbl, sgm.join(spacer)] unless sgm.empty?

        self
      else
        to_enum :each_segment
      end
    end

    def to_a(**options)
      map { |tk| tk.to_s(**options) }
    end

    def to_s(delimiter: "\n", **options)
      map { |tk| tk.to_s(**options) }.join(delimiter)
    end

    def to_h(**options)
      each_segment(**options).reduce({}) do |h, (label, segment)|
        h[label] = [] unless h.key? label
        h[label] << segment
        h
      end
    end

    def to_xml(xml = Builder::XmlMarkup.new)
      xml.sequence do |sq|
        each_segment do |(label, segment)|
          sq.tag! label, segment
        end
      end
    end

    def inspect
      "#<Wapiti::Sequence tokens={#{size}}>"
    end
  end
end
