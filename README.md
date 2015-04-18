
# Uga\_Uga

Don't use this.
Use [Treetop](https://github.com/nathansobo/treetop) or [OMeta](https://github.com/alexwarth/ometa-js).

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

  Uga_Uga.uga code do |name, blok|

    case name

    when "bobby"
      results << "bobby was called"
      blok

    when "howie"
      results << "howie was called"
      blok

    when "mandel"
      results << "mandel was called"
      blok

    when ":funny", '"comedian"'

    else
      fail ArgumentError, "Command not found: #{name.inspect}"
    end

  end

  puts results.inspect

```
