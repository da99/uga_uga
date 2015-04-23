
class Uga_Uga

  NEW_LINE_REGEXP = /\n/
  NOTHING         = ''.freeze
  REX             = /(\ {1,})|\(([^\)]+)\)|(.)/
  REX_CACHE       = {}

  module String_Refines
    refine String do
      def blank?
        strip.empty?
      end
    end
  end

  class << self

    #
    # This method is used mainly used in
    # tests/specs to remove the "noise"
    # (whitespace, empty lines, etc)
    # during parsing.
    #
    def clean arg
      case arg

      when String
        str = arg.strip
        return nil if str.empty?
        str

      when Array
        arg.map { |unknown| clean unknown }.compact

      else
        arg

      end
    end

    def reg_exp str, *custom
      i = -1
      base = str.scan(REX).map { |arr|
        case
        when arr[0]
          /\ */

        when arr[1]
          case arr[1].strip
          when '...'
            /\ *([^\)]+?)\ */

          when '_'
            i += 1
            fail ArgumentError, "NO value set for #{i.inspect} -> #{str.inspect}" unless custom[i]
            '(' + custom[i].to_s + ')'

          when 'word'
            /\ *([^\ \)]+)\ */

          when 'white*'
            /([\ ]*)/

          when 'white'
            /([\ ]+)/

          when 'num'
            /\ *([0-9\.\_\-]+)\ */

          else
            fail ArgumentError, "Unknown value for Regexp: #{arr[1].inspect} in #{str.inspect}"
          end

        when arr[2]
          Regexp.escape arr[2]

        else
          fail ArgumentError, "#{str.inspect} -> #{REG_EXP.inspect}"
        end
      }
      /\A#{base.join}\Z/
    end

  end # === class self ===

  attr_reader :stack, :line_num, :parent, :captures
  def initialize str_or_arr = nil, *args
    @origin   = str_or_arr
    @instruct = block_given? ? Proc.new : nil
    @stack    = []

    @captures      = nil
    @parent        = nil
    file_or_number = nil

    args.each { |o|
      case o
      when Uga_Uga
        @parent = o
        file_or_number ||= o.line_num

      when Numeric
        file_or_number = o

      when String
        file_or_number = o

      else
        fail ArgumentError, "Unknown argument: #{o.inspect}"
      end
    }

    return unless @origin

    if str_or_arr.is_a?(String)
      str    = str_or_arr
      @lines = str_or_arr.split(NEW_LINE_REGEXP)
    else
      str    = nil
      @lines = str_or_arr
    end

    @origin   = str_or_arr
    @old      = []
    @line_num = if file_or_number.is_a? Numeric
                  file_or_number
                else
                  contents = File.read(file_or_number || __FILE__ )
                  index    = contents.index(str || @lines.join("\n"))
                  if index
                    contents[0,index + 1].split("\n").size
                  else
                    1
                  end
                end
    run
  end # === def uga

  def rex? str, *args
    key     = [str,args].to_s
    reg_exp = ( REX_CACHE[key] ||= Uga_Uga.reg_exp(str, *args) )
    match = l!.match reg_exp
    @captures = match ?
                  match.captures :
                  nil
    !!match
  end

  def l!
    @lines.first
  end

  private # ===============================================

  def bracket l, close
    index = l.index(/[^\ ]/)
    "#{" " * index}#{close}"
  end

  def skip
    throw :skip
  end

  def white?
    l!.strip.empty?
  end

  def first *args
    l!.split.first.split(*args).first.strip
  end

  def split *args
    l!.split *args
  end

  def save_as cmd, data = nil
    @stack.last[:type] = cmd
    if data
      @stack.<<( @stack.pop.merge(data) )
    end
    @stack.last
  end

  def shift
    @old << @lines.shift
    @line_num = @line_num + 1
    @old.last
  end

  def head? str_or_rxp
    rxp = if str_or_rxp.is_a?(String)
            e = Regexp.escape str_or_rxp
            /\A\ *#{e}/
          else
            str_or_rxp
          end
    l![rxp]
  end

  def tail? str_or_rxp
    rxp = if str_or_rxp.is_a?(String)
            e = Regexp.escape str_or_rxp
            /#{e}\ *\z/
          else
            str_or_rxp
          end
    l![rxp]
  end

  def grab_all
    blok = []
    while !@lines.empty?
      blok << shift
    end

    blok
  end

  def grab_all_or_until period
    grab_until period, :close_optional
  end

  def grab_until period, *opts
    new_cmd  = nil
    blok     = []
    found    = false
    line_num = @line_num

    is_line = period.is_a?(Regexp) ? period : /\A#{Regexp.escape period}\ *\Z/

    while !found && (l = shift)
      if !(found =l[is_line])
        blok << l
      end
    end

    if !found && !opts.include?(:close_optional)
      fail ArgumentError, "Missing from around line number: #{line_num}: #{period.inspect}\n#{blok.join "\n"}"
    end

    blok
  end

  def run *args
    return(Uga_Uga.new(*args, &@instruct)) unless args.empty?
    return @stack unless @stack.empty?

    while !@lines.empty?
      size = @lines.size
      num = line_num
      catch(:skip) do
        result = instance_eval(&@instruct)
        if result.is_a?(Hash)
          @stack << result
          @stack.last[:line_num] = num
        end
      end
      shift if size == @lines.size
    end

    @stack.each { |h|
      next if !h[:raw] || h[:done?]

      if h[:type] == String
        h[:output] = h[:raw].join("\n")
        h.delete :raw
        next
      end

      if h[:type] == Array
        h[:output] = h[:raw]
        h.delete :raw
        next
      end

      h[:output] = Uga_Uga.new(h.delete(:raw), h[:line_num], self, &@instruct).stack
    }
  end # === def run


end # === class Uga_Uga ===
