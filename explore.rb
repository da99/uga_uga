
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
  def initialize str, file_or_number = nil
    @instruct = Proc.new
    @stack    = []
    @origin   = str
    @lines    = str.split(NEW_LINE_REGEXP)
    @line_num = if file_or_number.is_a? Numeric
                  file_or_number
                else
                  contents = File.read(file_or_number || __FILE__ )
                  index    = contents.index(str)
                  if index
                    contents[0,index + 1].split("\n").size
                  else
                    1
                  end
                end

    @old = []
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
    l!.split(*args).first
  end

  def split *args
    l!.split *args
  end

  def save_as cmd
    @stack.last[:command] = cmd
  end

  def shift
    @old << @lines.shift
    @old.last
  end

  def grab_until *args
    new_cmd = nil
    args.detect { |str|
      bookends = str.split
      size  = bookends.size

      case size

      when 1
        blok    = []
        found   = false
        period  = bookends.first
        at_end  = /\ +#{Regexp.escape period}\ *\z/
        is_line = /\A\ *#{Regexp.escape period}\ *\z/

        if found = (l = shift)[at_end]
          at_end = true
          blok << l
        end

        while !found && (l = shift)
          if !(found =l[is_line])
            blok << l
          end
        end

        new_cmd = {
          :command    => period,
          :block      => blok,
          :block_type => period,
          :one_line   => (at_end === true)
        }

      when 2
        open, close = bookends.map { |str|  Regexp.escape str }

        # eg: my command {{var}} { osmosdmf df}
        if @lines.first[/\A(.+?)\ (?<!#{open})#{open}(?!#{open})(.+)(?<!#{close})#{close}(?!#{close})\ *\Z/]
          shift
          new_cmd = {
            :command => $1,
            :block   => $2,
            :block_type => "#{open} #{close}"
          }
        else
          blok = []
          found = false
          cmd   = shift
          index = @lines.first.index(/[^\ ]/)
          close = /\A#{' ' * index}#{bookends.last}\ *\Z/
          while !found && l = shift
            found = l[close]
            if !found
              blok << l
            end
          end
          new_cmd = {
            :command => cmd,
            :block   => blok,
            :block_type => bookends.join(' ')
          }
        end

      else
        fail ArgumentError, "Either one or two pieces allowed: #{str.inspect}"
      end # === case size

      new_cmd
    } # === detect

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
    return @stack

      case action

      when :ignore

      when :insert
        stack << l

      when Hash
        stack << action

      when String, Regexp
        blok  = []
        found = false

        if action.is_a? String
          found = cmd[/\ #{Regexp.escape action}\ *\Z/]
          if !found
            index  = cmd.index /[^\ ]/
            action = /\A#{' ' * index}#{Regexp.escape action}\ *\Z/
          end
        end

        while !found && ( l = lines.shift )
          if l =~ action
            found = true
          else
            blok << l
          end
        end

        new_cmd = {
          :command => cmd,
          :block   => blok
        }

      #when Array

      else
        fail ArgumentError, "Unknown action from #{is_command}: #{action.inspect}"
      end # === case

      if new_cmd && new_cmd[:block].is_a?(Array)
        new_cmd[:block] = if do_eval
                            block(new_cmd[:block], is_command)
                          else
                            new_cmd[:block]
                          end
        stack << new_cmd
      end

    stack
  end # === def block

end # === class Uga_Uga

using Uga_Uga::String_Refines
str = "

Text $!!!
  This is a string.
    So is this.
    So is this.
    So is this.
$!!!

style {
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
  tag = first().split('.').first
  # l[/\A\ *(a|p|style|span|color|Text )/]
  case
  when tag == 'style' || tag  == 'color' || first()[/(?!\{)\{(?<!\{)/]
    grab_until '{ }'
  when tag == 'Text' && split.size == 2
    target = shift
    grab_until(target.split.last)
    save_as :text
  else
    grab_until  "/#{tag}", '{ }'
    save_as tag.to_sym
  end
end

# puts "================================"
# puts str
# puts "================================"

ap(uga.stack)
puts "=== DONE ======================="




