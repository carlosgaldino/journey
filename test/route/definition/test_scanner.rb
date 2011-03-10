require 'helper'

module Rack
  module Route
    module Definition
      class TestScanner < MiniTest::Unit::TestCase
        def setup
          @scanner = Definition::Scanner.new
        end

        # /page/:id(/:action)(.:format)
        def test_tokens
          [
            ['/',      [[:SLASH, '/']]],
            ['/page',  [[:SLASH, '/'], [:LITERAL, 'page']]],
            ['/:page', [[:SLASH, '/'], [:SYMBOL, ':page']]],
            ['/(:page)', [
                          [:SLASH, '/'],
                          [:LPAREN, '('],
                          [:SYMBOL, ':page'],
                          [:RPAREN, ')'],
                        ]],
            ['(/:action)', [
                            [:LPAREN, '('],
                            [:SLASH, '/'],
                            [:SYMBOL, ':action'],
                            [:RPAREN, ')'],
                           ]],
            ['(())', [[:LPAREN, '('],
                     [:LPAREN, '('], [:RPAREN, ')'], [:RPAREN, ')']]],
            ['(.:format)', [
                            [:LPAREN, '('],
                            [:DOT, '.'],
                            [:SYMBOL, ':format'],
                            [:RPAREN, ')'],
                          ]],
          ].each do |str, expected|
            @scanner.scan_setup str
            assert_tokens expected, @scanner
          end
        end

        def assert_tokens tokens, scanner
          toks = []
          while tok = scanner.next_token
            toks << tok
          end
          assert_equal tokens, toks
        end
      end
    end
  end
end