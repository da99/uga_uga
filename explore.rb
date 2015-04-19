
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
end

using Uga_Uga::String_Refines
str = "
style {
  a, b.name! {
    color red
  }
}


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

data = []
lines = str.split(NEW_LINE_REGEXP)
while l = lines.shift
  case

  when l == ""
    # do nothing
    #
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

  end
end

ap data
