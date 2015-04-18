
class Uga_Uga

  class << self

    def uga origin
      tokens = blockenize(tokenize(origin))

      case
      when block_given?
        run(tokens) do |cmd, block|
          yield cmd, block
        end
      else
        tokens
      end
    end

    def tokenize origin
      origin.split(/(\n)|((?<!\{)\{(?!\{))|((?<!\})\}(?!\}))/)
    end

    def blockenize raw
      tokens  = raw.dup
      final   = []
      stack   = []
      current = final
      last    = nil
      while t = tokens.shift
        case t
        when '{'
          stack << current
          current << (b = [])
          current = b
        when '}'
          current = stack.pop
        when ''
          # ignore
        else
          current << t
        end
      end # === while
      final
    end

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

    def run raw
      arr = raw.dup
      while t = arr.shift
        case

        when t.is_a?(String) && arr.first.is_a?(Array)
          blok    = arr.shift
          results = yield t.strip, blok
          if results == blok
            run results do |arg1, arg2|
              yield  arg1, arg2
            end
          end

        when t.is_a?(String) && (arr.first != arr.is_a?(Array))
          str = t.strip
          if !str.empty?
            yield str, nil
          end

        else
          fail ArgumentError, "Syntax: #{t.inspect} in #{raw.join.inspect}"

        end
      end
    end # === def run

  end # === class self ===

end # === class Uga_Uga ===
