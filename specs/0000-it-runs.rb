
describe "Uga_Uga" do

  it "runs" do
    o = Uga_Uga.uga(<<-EOF)
      p {
        "my paragraph"
      }
    EOF

    Uga_Uga.clean(o).should == [
      'p', ['"my paragraph"']
    ]
  end

  it "runs code from README.md" do
    file     = File.expand_path(File.dirname(__FILE__) + '/../README.md')
    contents = File.read( file )
    code     = (contents[/```ruby([^`]+)```/] && $1).gsub('puts ','')

    result = eval(code, nil, file, contents.split("\n").index('```ruby') + 1)
    result.should.match /bobby/
  end # === it

  it "accepts commands" do
    result = []
    Uga_Uga.uga "p { }" do |cmd, block|
      result << cmd.to_sym
    end

    result.should == [:p]
  end # === it

  it "parses inner blocks" do
    code = <<-EOF
      p {
        span {
          inner { "my" }
        }
      }
    EOF

    Uga_Uga.clean(Uga_Uga.uga code).
      should == [
        "p", [
          "span", [
            "inner", ['"my"']
          ]
        ]
    ]
  end

  it "runs the inner block" do
    result = []
    code = <<-EOF
      p {
        span {
          1 {
            2 {
              3 { "my text" }
            }
          }
        }
      }
    EOF

    Uga_Uga.uga(code) do |cmd, code|
      if cmd['"']
        result << cmd
      else
        result << cmd.to_sym 
      end
      code
    end

    result.should == [:p, :span, :'1', :'2', :'3', '"my text"']
  end # === it

  it "passes all text before a block start: cmd, cmd {" do
    result = []
    code = %^
      cmd, cmd {
        inner, inner {
        }
      }
    ^
    Uga_Uga.uga(code) do |cmd, code|
      result << cmd
      code
    end
    result.should == ["cmd, cmd", "inner, inner"]
  end # === it

end # === describe "Uga_Uga"
