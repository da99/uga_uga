
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

  class << self

    def is_command? l, *args
      case

      when l == ""
        :ignore

      when l[/\A\ *Text\ *([^\ ]+)\ *\Z/]
        /\A\ *#{Regexp.escape $1}\ *\Z/

      # when l[/\A(.+?)\ (?<!\{)\{(?!\{)(.+)(?<!\})\}(?!\})\ *\Z/] # eg: my command {{var}} { osmosdmf df}
        # {
          # :command => $1,
          # :block   => $2
        # }

      # when l[/[^\{]\{\ *\Z/] # ... {
        # index = l.index(/[^\ ]/)
        # (' ' * index) + '}'

      else
        :insert

      end # === case
    end # === def is_command?

    def uga str, is_command = :is_command?
      block(
        str.split(NEW_LINE_REGEXP),
        is_command
      )
    end # === def uga

    def block lines, is_command = :is_command?
      stack = []
      while l = lines.shift
        cmd = l
        action = case is_command
                 when Symbol
                   send(is_command, l)
                 when Proc
                   is_command.call l, stack
                 else
                   fail ArgumentError, "Unknown class: #{is_command.inspect}"
                 end

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

          stack.<<(
            {
              :command => cmd,
              :block   => blok
            }
          )

        when Array
          options = {}
          stack_size = stack.size
          action.detect { |str|

            break if stack_size != stack.size
            if str.is_a?(Symbol)
              options[str] = true
              next
            end

            bookends = str.split

            size  = bookends.size

            case size

            when 1
              period = bookends.first
              at_end = /\ +#{Regexp.escape period}\ *\z/

              if !options[:no_one_liner] && cmd[at_end] # p my parapgraph/p
                stack.<<(
                  :command => cmd,
                  :block   => cmd.sub(at_end, NOTHING),
                  :period  => period
                )
              else
                blok  = []
                found = false
                is_line = /\A\ *#{Regexp.escape period}\ *\z/


                while !found && l = lines.shift
                  if !(found = l[is_line])
                    blok << l
                  end
                end

                if l != period
                  fail "Not found: #{period.inspect}"
                end

                stack.<<(
                  :command    => cmd,
                  :block      => blok,
                  :block_type => period
                )
              end # === if

            when 2
              open, close = bookends.map { |str|  Regexp.escape str }

              # eg: my command {{var}} { osmosdmf df}
              if cmd[/\A(.+?)\ (?<!#{open})#{open}(?!#{open})(.+)(?<!#{close})#{close}(?!#{close})\ *\Z/]
                stack.<<(
                  :command => $1,
                  :block   => $2,
                  :block_type => [:one_line, bookends]
                )
              else
                blok = []
                found = false
                index = cmd.index(/[^\ ]/)
                close = /\A#{' ' * index}#{bookends.last}\ *\Z/
                while !found && l = lines.shift
                  found = l[close]
                  if !found
                    blok << l
                  end
                end
                stack.<<(
                  :command => cmd,
                  :block   => blok,
                  :block_type => bookends
                )
              end

            else
              fail ArgumentError, "Either one or two pieces allowed: #{str.inspect}"
            end # === case size

            false
          }

        else
          fail ArgumentError, "Unknown action from #{is_command}: #{action.inspect}"
        end

      end # === while l

      stack
    end # === def block

  end # === class << self

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

color {{ name }} { This is text { } }
p
  id hello
  a galaxy://dd Visit my galaxy
  a http://dd
    visit my galaxy
  a
    http://ddd
    visit my galaxy
  a pop!
    http://ddd
    visit my galaxy
  ----------------------------
  I am a paragraph that goes +!
  on and                     +!
  on.
/p
"


is_command = lambda { |l, *args|
  return :ignore if l == ""
  if l[/\A\ *(a|p|style|span|color|Text )/]
    case
    when $1 == 'style' || $1 == 'color'
      ['{ }']
    when $1 == 'Text ' && l.split.size == 2
      [:no_one_liner, l.split.last]
    else
      ["/#{$1}", '{ }']
    end
  else
    fail "Unknown command: #{l.inspect}"
  end
}

puts "================================"
puts "\n\n\n"
results = Uga_Uga.uga str, is_command

# puts "================================"
# puts str
# puts "================================"

ap(results)
puts "=== DONE ======================="




