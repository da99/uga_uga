
require "awesome_print"
NEW_LINE_REGEXP = /\n/

class Uga_Uga

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

      when l[/\A(.+?)\ (?<!\{)\{(?!\{)(.+)(?<!\})\}(?!\})\ *\Z/] # eg: my command {{var}} { osmosdmf df}
        {
          :command => $1,
          :block   => $2
        }

      when l[/[^\{]\{\ *\Z/] # ... {
        index = l.index(/[^\ ]/)
        (' ' * index) + '}'

      else
        :insert

      end # === case
    end # === def is_command?

    def uga str, is_command = :is_command?

      stack = []
      data  = {}
      lines = str.split(NEW_LINE_REGEXP)

      while l = lines.shift
        action = case is_command
                 when Symbol
                   send(is_command, l, data)
                 when Proc
                   is_command.call l, stack, data
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
          blok = []
          found = false

          cmd = l

          while !found && ( l = lines.shift )
            found = action.is_a?(String) ?
              (l == action) :
              (l =~ action)
            (blok << l) unless found
          end

          stack.<<(
            {
              :command => cmd,
              :block   => blok
            }
          )

        else
          fail ArgumentError, "Unknown action from #{is_command}: #{action.inspect}"
        end

      end # === while l

      stack
    end # === def uga

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

p.name!
 thus iss  a { { { strung
/p

span {{ name }} { This is text { } }
p {
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
}
"

puts "================================"
puts str
puts "================================"


is_command = lambda { |l, *args|
  Uga_Uga.is_command? l, *args
}

results = Uga_Uga.uga str, is_command
ap(results)




