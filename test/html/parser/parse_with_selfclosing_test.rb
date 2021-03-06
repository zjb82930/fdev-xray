require_relative '../../helper'

module XRayTest
  module HTML
    module Parser

      class ParseWithSelfClosingTagTest < Test::Unit::TestCase
        
        include XRay::HTML
        
        def setup
          @parser = XRay::HTML::Parser.new('<div class="info" />')
          @element = @parser.parse
        end

        def test_is_a_div_element
          assert @element.is_a?(Element)
          assert @element.tag_name, 'div'
        end

        def test_have_one_child
          assert @element.children.empty?
        end

        def test_has_text
          assert_equal '', @element.inner_text
        end

        def test_has_html_text
          assert_equal '', @element.inner_html
          assert_equal '<div class="info" />', @element.outer_html
        end

      end

    end
  end
end
