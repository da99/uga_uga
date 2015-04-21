
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


  attr_reader :stack
  def initialize str_or_arr, file_or_number = nil
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

    @stack.<<(
      :type  => :unknown,
      :block => blok
    )
  end

  def grab
    @stack.<<(
      :type  => :unknown,
      :block => [shift]
    )
  end

  def grab_until period
    new_cmd = nil
    blok    = []
    found   = false
    at_end  = /\ +#{Regexp.escape period}\ *\z/
    is_line = /\A\ *#{Regexp.escape period}\ *\z/

    if found = (l!)[at_end]
      blok << shift
      at_end = true
    end

    while !found && (l = shift)
      if !(found =l[is_line])
        blok << l
      end
    end

    new_cmd = {
      :type    => period,
      :block   => blok,
      :etc     => [period]
    }

    if !new_cmd
      fail "Not found: #{cmd.inspect} --> #{action.inspect}"
    end

    @stack << new_cmd
  end

  def run
    stack = []

    while !@lines.empty?
      catch :skip do
        instance_eval &@instruct
      end
      shift
    end

    @stack.each { |h|
      next if h[:done?] || h[:type] == :raw

      if h[:type] == String
        h[:output] = h[:block].join("\n")
        h.delete :block
        next
      end

      if h[:type] == Array
        h[:output] = h[:block]
        h.delete :block
        next
      end

      next unless h[:type].is_a?(Symbol) || h[:type].is_a?(String)
      ap h[:block]
      h[:output] = Uga_Uga.new(h[:block], &@instruct).stack
    }
  end # === def run

end # === class Uga_Uga

using Uga_Uga::String_Refines
str = "

Text $!!!
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
    visit my galaxy
  /a
  a
    http://ddd
    visit my galaxy
  /a
  a pop!
    http://ddd
    visit my galaxy
  /a
  ----------------------------
  I am a paragraph that goes +!
  on and                     +!
  on.
/p
"

puts "================================"
puts "\n\n\n"

uga = Uga_Uga.new(str) do

  skip if white?

  case
  when tail?('{')
    selectors = shift
    grab_until '}'
    save_as :css, :selectors => selectors

  when tail?('}') && l![/\A\ *(.+)\{\ *(.+)\ *\}\ *\Z/] # === div.col!, div.red { ... }
    selectors = $1
    content   = $2
    grab
    save_as :css, :selectors => selectors, :block=>[$2], :one_liner=>true

  when head?('Text') && (pieces = split).size == 2
    shift
    grab_until(pieces.last)
    save_as String

  when head?('color')
    line = l!
    grab
    save_as :css_property, :name=>:color, :value => line.sub('color', ''), :done? => true

  else
    tag = first('.')
    if tail?("/#{tag}")
      grab
      save_as :html, :tag=>tag.to_sym, :one_liner=>true, :done? => true
    else
      tag = tag.to_sym
      case tag
      when :p
        selector = shift
        grab_until "/#{tag}"
        save_as :html, :tag=>tag, :selector => selector
      else
        if stack.empty? || l![/\A\ *(\-{4,})\ *\Z/]
          grab_all
          save_as String
        else
          fail ArgumentError, "Unknown: #{l!.inspect}"
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




