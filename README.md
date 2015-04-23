
# Uga\_Uga

Don't use this.
Use [Parslet](http://kschiess.github.io/parslet/) or [OMeta](https://github.com/alexwarth/ometa-js).

Here is a video on creating your own external DSL:
[Writing DSL's with Parslet by Jason Garber](https://www.youtube.com/watch?v=ET_POMJNWNs)

## Installation

    gem 'uga_uga'

## Usage

```ruby
  require "uga_uga"

  code = <<-EOF
    bobby {
      howie { :funny }
      mandel { "comedian" }
    }
  EOF

  results = []

  Uga_Uga.new code do

    case

    when rex?("(white*)(word) { ")
      line = shift
      results << "#{captures.last} was called"
      {:raw=>grab_until(bracket(line, '}'))}

    when rex?(" (word) { (...) } ")
      results << "#{captures.first} called with #{captures.last}"

    else
      fail ArgumentError, "Command not found: #{l!.inspect}"

    end # === case name

  end # === .new

  results

```
