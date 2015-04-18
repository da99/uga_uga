
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

end # === describe "Uga_Uga"
