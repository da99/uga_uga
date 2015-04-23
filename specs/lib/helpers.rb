
require 'Bacon_Colored'
require 'uga_uga'
require 'pry'
require 'awesome_print'

module Bacon
  class Context

    def clean o
      return o.strip if o.is_a?(String)
      return o unless o.is_a?(Array) || o.is_a?(Uga_Uga)

      return clean(o.stack) if o.respond_to?(:stack)

      o.inject([]) do |memo, hash|
        memo << hash[:type] unless hash[:type] == String
        memo << clean(hash[:output])
        memo
      end
    end

  end # === class Context
end # === module Bacon


WWW_APP = Uga_Uga.new do

  skip if white?

  case
  when rex?("(white*)(...) { ")                    # === multi-line css
    close = captures.first
    shift
    final = {
      :type      => :css,
      :selectors => captures.last,
      :raw       => grab_until(/\A#{close}\}\ *\Z/)
    }

  when rex?(" (...) { (...) } ")              # === css one-liner
    selectors , content = captures
    shift
    final = {
      :type      => :css,
      :selectors => selectors,
      :raw       => [content],
      :one_liner => true
    }

  when rex?(" String (word) ")                   # === Multi-line String
    close = captures.first
    shift
    final = {
      :type   => String,
      :output => grab_until(/\A\ *#{Regexp.escape close}\ *\Z/).join("\n")
    }

  when rex?(" color (word) ")
    #  l![/\A\ *color\ *([a-zA-Z0-9\-\_\#]+)\ *\Z/]
    val = captures.first
    final = {
      :type  => :css_property,
      :name  => :color,
      :output=> val
    }

  when rex?(" id (word) ")
    #  l![/\A\ *id\ *([a-zA-Z0-9\-\_\#]+)\ *\Z/]
    val = captures.first
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
        line    = shift
        bracket = bracket(line, "/#{tag}")
        final = {:type=>:html, :tag=>tag, :selector => line, :raw=>grab_until(bracket)}
        final
      else
        if stack.empty?
          {:type=>String, :raw=>grab_all}
        elsif rex?(" (_) ", /\-{4,}/)     # Start of multi-line string --------------------
          eos = l!.rstrip
          shift
          {:type=>String, :raw=>grab_all_or_until(/\A#{eos}\ *|Z/)}
        else
          fail ArgumentError, "Unknown command: #{line_num}: #{l!.inspect}"
        end
      end
    end

  end # === case

end # === .new
