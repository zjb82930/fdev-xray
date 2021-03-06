require_relative '../node'

module XRay
  module HTML

    Node = XRay::Node

    class Element < Node

      attr_reader :tag, :props, :children

      def initialize(tag, props=[], children=[])
        @tag, @prop, @children = tag, props||[], Array.[](children).flatten || []
      end

      def text
        children.inject("") do |s,child|
          s + child.text
        end
      end

      def tag_name
        @tag.is_a?(Node) ? @tag.text : @tag.to_s
      end

      def inner_html
        @children.inject('') { |s,c| s + c.outer_html }
      end

      def outer_html
        if children.empty?
          "<#{@tag}#{prop_text} />"
        else
          "<#{@tag}#{prop_text}>#{inner_html}</#{@tag}>"
        end
      end

      def inner_text
        @children.inject('') { |s,c| s + c.inner_text }
      end

      def prop_text
        to_param_string(@prop)
      end

      def ==(other)
        tag_name == tag_name.to_s && prop_text == other.prop_text && inner_html == other.inner_html
      end

      def to_s
        "< \##{outer_html}>"
      end

      protected
      def parse(text)
        @outer_html = text
      end

      private
      def to_param_string( props )
        case props
          when Array
            props.inject('') { |s, p| s << " " << p.to_s }
          when Hash
            props.inject('') { |s, p| s + %Q( #{p[0]}="#{p[1]}") }
        end
      end

    end


    class TextElement < Element

      def initialize(text="")
        super(nil)
        @text = text.to_s
      end

      def text; @text; end
      def tag_name; nil; end

      alias_method :inner_text, :text
      alias_method :inner_html, :text
      alias_method :outer_html, :text

      def ==(other)
        text == other.text
      end

    end


    class CommentElement < Element
      def children
        nil
      end
    end


    class Property < Node

      attr_reader :name, :value, :sep

      def initialize(name, value, sep='"')
        @name, @value, @sep = name, value, sep
      end

      def position
        name.position
      end

      def to_s
        "#{name}=#{sep}#{value}#{sep}"
      end

    end

    class TagNameNode < Node
    end


  end
end

if $0 == __FILE__
  Element = XRay::HTML::Element
  TextElement = XRay::HTML::TextElement
  Property = XRay::HTML::Property
  puts TextElement.new('hello').inner_text
  puts Element.new('div', {:class => 'info'}).outer_html
  puts Element.new('div', [Property.new('class', 'info')]).outer_html
  puts Element.new('div', {:class => 'info', :id => 'sample'}) == Element.new('div', [Property.new('class', 'info'), Property.new('id', 'sample')])
end
