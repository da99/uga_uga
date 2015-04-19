
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

  def is_command? l
    case

    when l == ""
      :ignore

    when l[/\A\ *Text\ *([^\ ]+)\ *\Z/]
      eos = /\A\ *#{Regexp.escape $1}\ *\Z/

    when l[/\A(.+?)\ (?<!\{)\{(?!\{)(.+)(?<!\})\}(?!\})\ *\Z/] # eg: my command {{var}} { osmosdmf df}
      {
        :command => $1,
        :block   => $2
      }

    when l[/[^\{]\{\ *\Z/] # ... {
      data << (blok = {:command=> l.sub(/\{\ *\Z/, ''), :block=>[]})
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
            (l =~ Regexp)
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

  end # === def uga

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

while l = lines.shift
  case

  when l == ""
    # do nothing


  when l[/\A\ *Text\ *([^\ ]+)\ *\Z/]
    eos = /\A\ *#{Regexp.escape $1}\ *\Z/
    text = []
    while lines.first && lines.first !~ eos
      text << lines.shift
    end
    lines.shift
    data << {:command => :string, :block => text.join("\n")}

  when l[/\A(.+?)\ (?<!\{)\{(?!\{)(.+)(?<!\})\}(?!\})\ *\Z/] # eg: my command {{var}} { osmosdmf df}
    data << {
      :command => $1,
      :block   => $2
    }

  when l[/[^\{]\{\ *\Z/] # ... {

    data << (blok = {:command=> l.sub(/\{\ *\Z/, ''), :block=>[]})
    index = l.index(/[^\ ]/)
    found = false
    while !found && ( blok_l = lines.shift )
      brace = blok_l.index '}'
      if brace && brace == (index)
        (found = true)
      else
        blok[:block] << blok_l
      end
    end

  else
    data << l

  end # === case
end

ap data
