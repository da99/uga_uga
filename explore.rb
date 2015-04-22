
require "awesome_print"
NEW_LINE_REGEXP = /\n/

class Uga_Uga

  NOTHING = ''.freeze

  module String_Refines
    refine String do
      def blank?
        strip.empty?
      end
    end
  end


  attr_reader :stack, :line_num, :parent
  def initialize str_or_arr, *args
    @parent = nil
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

    if str_or_arr.is_a?(String)
      str    = str_or_arr
      @lines = str_or_arr.split(NEW_LINE_REGEXP)
    else
      str    = nil
      @lines = str_or_arr
    end

    @old      = []
    @instruct = Proc.new
    @stack    = []
    @origin   = str_or_arr
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

  def l!
    @lines.first
  end

  private # ===============================================

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

  def run
    return @stack unless @stack.empty?

    while !@lines.empty?
      size = @lines.size
      num = line_num
      catch(:skip) do
        @stack << instance_eval(&@instruct)
        @stack.last[:line_num] = num
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

end # === class Uga_Uga

using Uga_Uga::String_Refines
str = <<-EOF

String $!!!
  This is a string.
    So is this.
    So is this.
    So is this.
$!!!

div {
  a, b.name! {
    color red
  }
}

a http://something This is a paragraph. /a

p.id!.class.class This is a paragraph. /p

p.name!
 thus iss  a { { { strung
/p

a.red, div.red { color red }

p
  id hello
  a galaxy://dd Visit my galaxy /a
  a http://dd
    visit my galaxy 1
  /a
  a
    http://ddd
    visit my galaxy  2
  /a
  a pop!
    http://ddd
    visit my galaxy 3
  /a
  ----------------------------
  I am a paragraph that goes +!
  on and                     +!
  on.
/p
EOF

puts "================================"
puts "\n\n\n"

uga = Uga_Uga.new(str) do

  skip if white?

  case
  when l![/\A(\ *)([^\{]+)\ *\{\ *\Z/]        # === multi-line css
    indent = $1
    close = 
    shift
    final = {
      :type      => :css,
      :selectors => $2,
      :raw       => grab_until(/\A#{indent}\}\ *\Z/)
    }

  when l![/\A\ *(.+)\{\ *(.+)\ *\}\ *\Z/]     # === css one-liner
    selectors = $1
    content   = $2
    shift
    final = {
      :type      => :css,
      :selectors => selectors,
      :raw       => [$2],
      :one_liner => true
    }

  when l![/\A\ *String\ *([^\ ]+)\ *\Z/]        # === Multi-line String
    close = $1
    shift
    final = {
      :type   => String,
      :output => grab_until(/\A\ *#{Regexp.escape close}\ *\Z/).join("\n")
    }

  when l![/\A\ *color\ *([a-zA-Z0-9\-\_\#]+)\ *\Z/]
    val = $1
    final = {
      :type  => :css_property,
      :name  => :color,
      :output=> val
    }

  when l![/\A\ *id\ *([a-zA-Z0-9\-\_\#]+)\ *\Z/]
    val = $1
    final = {
      :type  => :id!,
      :output=> val
    }

  else
    tag = first('.')
    if tail?("/#{tag}")
      {:type=>:html, :tag=>tag.to_sym, :one_liner=>true, :output => shift}
    else
      tag = tag.to_sym
      case tag
      when :p, :a
        index = l!.index(/[^\ ]/)
        {:type=>:html, :tag=>tag, :selector => shift, :raw=>grab_until("#{" " * index}/#{tag}")}
      else
        if stack.empty?
          {:type=>String, :raw=>grab_all}
        elsif l![/\A(\ *\-{4,})\ *\Z/]     # Start of multi-line string --------------------
          eos = $1
          shift
          {:type=>String, :raw=>grab_all_or_until(/\A#{eos}\ *|Z/)}
        else
          fail ArgumentError, "Unknown command: #{line_num}: #{l!.inspect}"
        end
      end
    end

  end # === case

end # === do

# puts "================================"
# puts str
# puts "================================"

ap(uga.stack, :indent=>-2)
puts "=== DONE ======================="




